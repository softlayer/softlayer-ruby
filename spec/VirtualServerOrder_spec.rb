#
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
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
require 'URI'

describe SoftLayer::VirtualServerOrder do
  before(:each) do
    SoftLayer::VirtualServerOrder.send(:public, *SoftLayer::VirtualServerOrder.protected_instance_methods)
  end

  let (:subject) do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')
    SoftLayer::VirtualServerOrder.new(client)
  end

  it "places its :datacenter attribute into the order template" do
    subject.virtual_guest_template["datacenter"].should be_nil
    subject.datacenter = "dal05"
    subject.virtual_guest_template["datacenter"].should == { "name" => "dal05" }
  end

  it "places its :hostname attribute into the order template" do
    subject.virtual_guest_template["hostname"].should be_nil
    subject.hostname = "testhostname"
    subject.virtual_guest_template["hostname"].should == "testhostname"
  end

  it "places its :domain attribute into the order template" do
    subject.virtual_guest_template["domain"].should be_nil
    subject.domain = "softlayer.com"
    subject.virtual_guest_template["domain"].should == "softlayer.com"
  end
  
  it "places its :cores attribute into the order template as startCpus" do
    subject.cores = 4
    subject.virtual_guest_template["startCpus"].should == 4
  end

  it "places the MB value of the :memory attrbute in the template as maxMemory" do
    subject.memory = 4
    subject.virtual_guest_template["maxMemory"].should == 4096
  end

  it "places an OS identifier into the order template as the operatingSystemReferenceCode" do
    subject.virtual_guest_template["operatingSystemReferenceCode"].should be_nil
    subject.os_reference_code = 'UBUNTU_12_64'
    subject.virtual_guest_template['operatingSystemReferenceCode'].should == 'UBUNTU_12_64'
  end
  
  it "places an image template global identifier in the template as blockDeviceTemplateGroup.globalIdentifier" do
    subject.virtual_guest_template["blockDeviceTemplateGroup"].should be_nil
    subject.image_global_id = "12345-abcd-eatatjoes"
    subject.virtual_guest_template['blockDeviceTemplateGroup'].should == {'globalIdentifier' => '12345-abcd-eatatjoes'}
  end
  
  it "allows an image global id to override an os reference code when both are provided" do
    subject.virtual_guest_template["blockDeviceTemplateGroup"].should be_nil
    subject.virtual_guest_template["operatingSystemReferenceCode"].should be_nil

    subject.image_global_id = "12345-abcd-eatatjoes"
    subject.os_reference_code = 'UBUNTU_12_64'
  
    subject.virtual_guest_template['blockDeviceTemplateGroup'].should == {'globalIdentifier' => '12345-abcd-eatatjoes'}
    subject.virtual_guest_template['operatingSystemReferenceCode'].should be_nil
  end

  it "places the attribute :hourly into the template as hourlyBillingFlag converting the value to a boolean constant" do
    # note, we don't want the flag to be nil we want it to be eotjer false or true
    subject.virtual_guest_template["hourlyBillingFlag"].should be(false)
  
    subject.hourly = true
    subject.virtual_guest_template["hourlyBillingFlag"].should be(true)
  
    subject.hourly = false
    subject.virtual_guest_template["hourlyBillingFlag"].should be(false)
  end

  it "places the attribute :use_local_disk in the template as the localDiskFlag" do
    # note, we don't want the flag to be nil we want it to be false or true
    subject.virtual_guest_template["localDiskFlag"].should be(false)
  
    subject.use_local_disk = true
    subject.virtual_guest_template["localDiskFlag"].should be(true)
  
    subject.use_local_disk = false
    subject.virtual_guest_template["localDiskFlag"].should be(false)
  end

  it "places the attribute :dedicated_host_only in the template as dedicatedAccountHostOnlyFlag" do
    subject.virtual_guest_template["dedicatedAccountHostOnlyFlag"].should be_nil
    subject.dedicated_host_only = true
    subject.virtual_guest_template["dedicatedAccountHostOnlyFlag"].should be_true
  end

  it "puts the public VLAN id into an order template as primaryNetworkComponent.networkVlan.id" do
    subject.virtual_guest_template["primaryNetworkComponent"].should be_nil
    subject.public_vlan_id = 12345
    subject.virtual_guest_template["primaryNetworkComponent"].should == { "networkVlan" => { "id" => 12345 } }
  end
  
  it "puts the private VLAN id into an order template as primaryBackendNetworkComponent.networkVlan.id" do
    subject.virtual_guest_template["primaryBackendNetworkComponent"].should be_nil
    subject.private_vlan_id = 12345
    subject.virtual_guest_template["primaryBackendNetworkComponent"].should == { "networkVlan" => { "id" => 12345 } }
  end
  
  it "sets up disks in the order template as blockDevices" do
    subject.virtual_guest_template["blockDevices"].should be_nil
    subject.disks = [2, 25, 50]

    # note that device id 1 should be skipped as SoftLayer reserves that id for OS swap space.
    subject.virtual_guest_template["blockDevices"].should == [
      {"device"=>"0", "diskImage"=>{"capacity"=>2}},
      {"device"=>"2", "diskImage"=>{"capacity"=>25}},
      {"device"=>"3", "diskImage"=>{"capacity"=>50}}
    ]
  end

  it "puts the :ssh_key_ids in the template as sshKeys and breaks out the ids into objects" do
    subject.virtual_guest_template["sshKeys"].should be_nil
    subject.ssh_key_ids = [123, 456, 789]
    subject.virtual_guest_template['sshKeys'].should == [{'id' => 123}, {'id' => 456}, {'id' => 789}]
  end

  it "puts the :provision_script_URI property into the template as postInstallScriptUri" do
    subject.virtual_guest_template["postInstallScriptUri"].should be_nil
    subject.provision_script_URI = 'http:/provisionhome.mydomain.com/fancyscript.sh'
    subject.virtual_guest_template['postInstallScriptUri'].should == 'http:/provisionhome.mydomain.com/fancyscript.sh'
  end

  it "accepts URI objects for the provision script URI" do
    subject.virtual_guest_template["postInstallScriptUri"].should be_nil
    subject.provision_script_URI = URI.parse('http:/provisionhome.mydomain.com/fancyscript.sh')
    subject.virtual_guest_template['postInstallScriptUri'].should == 'http:/provisionhome.mydomain.com/fancyscript.sh'
  end
  
  it "places the private_network_only attribute in the template as privateNetworkOnlyFlag" do
    subject.virtual_guest_template["privateNetworkOnlyFlag"].should be_nil
    subject.private_network_only = true
    subject.virtual_guest_template["privateNetworkOnlyFlag"].should be_true
  end

  it "puts the user metadata string into the template as userData" do
    subject.virtual_guest_template["userData"].should be_nil
    subject.user_metadata = "MetadataValue"
    subject.virtual_guest_template['userData'].should == [{'value' => 'MetadataValue'}]
  end
 
  it "puts the max_port_speed attribute into the template as networkComponents.maxSpeed" do
    subject.virtual_guest_template["networkComponents"].should be_nil
    subject.max_port_speed = 1000
    subject.virtual_guest_template['networkComponents'].should == [{'maxSpeed' => 1000}]
  end

  it "calls the softlayer API to validate an order template" do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')

    test_order = SoftLayer::VirtualServerOrder.new(client)
    test_order.cores = 2
    test_order.memory = 2
    test_order.hostname = "ruby-client-test"
    test_order.domain = "kitchentools.com"

    virtual_guest_order_service = client["Virtual_Guest"]
    virtual_guest_order_service.stub(:call_softlayer_api_with_params)

    expect(virtual_guest_order_service).to receive(:generateOrderTemplate).with(test_order.virtual_guest_template)
    test_order.verify()
  end

  it "calls the softlayer API to place an order for a new virtual server" do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')

    test_order = SoftLayer::VirtualServerOrder.new(client)
    test_order.cores = 2
    test_order.memory = 2
    test_order.hostname = "ruby-client-test"
    test_order.domain = "kitchentools.com"

    virtual_guest_order_service = client["Virtual_Guest"]
    virtual_guest_order_service.stub(:call_softlayer_api_with_params)

    expect(virtual_guest_order_service).to receive(:createObject).with(test_order.virtual_guest_template)
    test_order.place_order!()
  end
  
  it "allows a block to modify the template sent to the server when verifying an order" do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')

    test_order = SoftLayer::VirtualServerOrder.new(client)
    test_order.cores = 2
    test_order.memory = 2
    test_order.hostname = "ruby-client-test"
    test_order.domain = "kitchentools.com"

    virtual_guest_order_service = client["Virtual_Guest"]
    virtual_guest_order_service.stub(:call_softlayer_api_with_params)

    substituted_order_template = { 'aFake' => 'andBogusOrderTemplate' }
    expect(virtual_guest_order_service).to receive(:generateOrderTemplate).with(substituted_order_template)
    test_order.verify() { |order_template| substituted_order_template }
  end

  it "allows a block to modify the template sent to the server when placing an order" do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')

    test_order = SoftLayer::VirtualServerOrder.new(client)
    test_order.cores = 2
    test_order.memory = 2
    test_order.hostname = "ruby-client-test"
    test_order.domain = "kitchentools.com"

    virtual_guest_order_service = client["Virtual_Guest"]
    virtual_guest_order_service.stub(:call_softlayer_api_with_params)

    substituted_order_template = { 'aFake' => 'andBogusOrderTemplate' }
    expect(virtual_guest_order_service).to receive(:createObject).with(substituted_order_template)
    test_order.place_order!() { |order_template| substituted_order_template }
  end

end
