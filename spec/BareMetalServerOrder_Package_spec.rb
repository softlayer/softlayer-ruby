#
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, test_order to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'softlayer_api'
require 'rspec'
require 'uri'

describe SoftLayer::BareMetalServerOrder_Package do
  before(:each) do
    SoftLayer::BareMetalServerOrder_Package.send(:public, *SoftLayer::BareMetalServerOrder_Package.protected_instance_methods)
  end

  let (:test_order) do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')

    package = SoftLayer::ProductPackage.new(client, fixture_from_json("Product_Package"))
    SoftLayer::BareMetalServerOrder_Package.new(client, package)
  end

  it 'places the package id from which it was ordered into the order template' do
    expect(test_order.hardware_order["packageId"]).to eq 32
  end

  it "places its :datacenter attribute into the order template" do
    expect(test_order.hardware_order["location"]).to be_nil
    test_order.datacenter = "sng01"
    expect(test_order.hardware_order["location"]).to eq 224092
  end

  it "places its :hostname attribute into the hardware template in the order" do
    expect(test_order.hardware_order['hardware']['hostname']).to be_nil
    test_order.hostname = "testhostname"
    expect(test_order.hardware_order['hardware']['hostname']).to eq "testhostname"
  end

  it "places its :domain attribute into into the hardware template in the order" do
    expect(test_order.hardware_order['hardware']['domain']).to be_nil
    test_order.domain = "softlayer.com"
    expect(test_order.hardware_order['hardware']['domain']).to eq "softlayer.com"
  end

  it "places config options as prices in the order" do
    test_order.configuration_options = {'os' => 1, 'ram' => 2}
    expect(test_order.hardware_order['prices']).to eq([{'id' => 1}, {'id' => 2}])
  end

  it "allows config options to be objects that respond to price_id" do
    config_option_1 = Object.new
    config_option_2 = Object.new

    def config_option_1.price_id
      1
    end

    def config_option_2.price_id
      2
    end

    test_order.configuration_options = {'os' => config_option_1, 'ram' => config_option_2}
    expect(test_order.hardware_order['prices']).to eq([{'id' => 1}, {'id' => 2}])
  end

  it "places its :ssh_key_ids attribute into into order" do
    expect(test_order.hardware_order['sshKeys']).to be_nil
    test_order.ssh_key_ids = [123, 456, 789]
    expect(test_order.hardware_order['sshKeys']).to eq([{ 'sshKeyIds' => [123, 456, 789]}])
  end

  it "places its :provision_script_URI attribute into into order" do
    expect(test_order.hardware_order['provisionScripts']).to be_nil
    test_order.provision_script_URI = 'https://testprovision.mydomain.org/fancyscript.sh'
    expect(test_order.hardware_order['provisionScripts']).to eq ['https://testprovision.mydomain.org/fancyscript.sh']
  end

  it "allows a URI object to be provided as the :provision_script_URI" do
    expect(test_order.hardware_order['provisionScripts']).to be_nil
    test_order.provision_script_URI = URI.parse('https://testprovision.mydomain.org/fancyscript.sh')
    expect(test_order.hardware_order['provisionScripts']).to eq ['https://testprovision.mydomain.org/fancyscript.sh']
  end

  it "calls the softlayer API to verify an order" do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')
    package = SoftLayer::ProductPackage.new(client, fixture_from_json("Product_Package"))

    order_service = client["Product_Order"]
    allow(order_service).to receive(:call_softlayer_api_with_params)

    test_order = SoftLayer::BareMetalServerOrder_Package.new(client, package)
    test_order.datacenter = 'sng01'
    test_order.hostname = "ruby-client-test"
    test_order.domain = "kitchentools.com"
    test_order.configuration_options = { 'category' => 123 }

    expect(order_service).to receive(:verifyOrder).with(test_order.hardware_order)
    test_order.verify()
  end

  it "calls the softlayer API to place an order" do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')
    package = SoftLayer::ProductPackage.new(client, fixture_from_json("Product_Package"))

    order_service = client["Product_Order"]
    allow(order_service).to receive(:call_softlayer_api_with_params)

    test_order = SoftLayer::BareMetalServerOrder_Package.new(client, package)
    test_order.datacenter = 'sng01'
    test_order.hostname = "ruby-client-test"
    test_order.domain = "kitchentools.com"
    test_order.configuration_options = { 'category' => 123 }

    expect(order_service).to receive(:placeOrder).with(test_order.hardware_order)
    test_order.place_order!()
  end

  it "allows a block to modify the template sent to the server when verifying an order" do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')
    package = SoftLayer::ProductPackage.new(client, fixture_from_json("Product_Package"))

    order_service = client["Product_Order"]
    allow(order_service).to receive(:call_softlayer_api_with_params)

    test_order = SoftLayer::BareMetalServerOrder_Package.new(client, package)
    test_order.datacenter = 'sng01'
    test_order.hostname = "ruby-client-test"
    test_order.domain = "kitchentools.com"
    test_order.configuration_options = { 'category' => 123 }

    substituted_order_template = { 'aFake' => 'andBogusOrderTemplate' }
    expect(order_service).to receive(:verifyOrder).with(substituted_order_template)
    test_order.verify() { |order_template| substituted_order_template }
  end

  it "allows a block to modify the template sent to the server when placing an order" do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')
    package = SoftLayer::ProductPackage.new(client, fixture_from_json("Product_Package"))

    order_service = client["Product_Order"]
    allow(order_service).to receive(:call_softlayer_api_with_params)

    test_order = SoftLayer::BareMetalServerOrder_Package.new(client, package)
    test_order.datacenter = 'sng01'
    test_order.hostname = "ruby-client-test"
    test_order.domain = "kitchentools.com"
    test_order.configuration_options = { 'category' => 123 }

    substituted_order_template = { 'aFake' => 'andBogusOrderTemplate' }
    expect(order_service).to receive(:placeOrder).with(substituted_order_template)
    test_order.place_order!() { |order_template| substituted_order_template }
  end
end
