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
require 'uri'

describe SoftLayer::BareMetalServerOrder do
  before(:each) do
    SoftLayer::BareMetalServerOrder.send(:public, *SoftLayer::BareMetalServerOrder.protected_instance_methods)
  end

  let (:subject) do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')
    SoftLayer::BareMetalServerOrder.new(client)
  end

  it "places its :datacenter attribute into the order template" do
    subject.hardware_instance_template["datacenter"].should be_nil
    subject.datacenter = "dal05"
    subject.hardware_instance_template["datacenter"].should == { "name" => "dal05" }
  end

  it "places its :hostname attribute into the order template" do
    subject.hardware_instance_template["hostname"].should be_nil
    subject.hostname = "testhostname"
    subject.hardware_instance_template["hostname"].should == "testhostname"
  end

  it "places its :domain attribute into the order template" do
    subject.hardware_instance_template["domain"].should be_nil
    subject.domain = "softlayer.com"
    subject.hardware_instance_template["domain"].should == "softlayer.com"
  end

  it "places its :cores attribute into the order template as startCpus" do
    subject.cores = 4
    subject.hardware_instance_template["processorCoreAmount"].should == 4
  end

  it "places the :memory attrbute in the template as memoryCapacity" do
    subject.memory = 4
    subject.hardware_instance_template["memoryCapacity"].should == 4
  end

  it "places an OS identifier into the order template as the operatingSystemReferenceCode" do
    subject.hardware_instance_template["operatingSystemReferenceCode"].should be_nil
    subject.os_reference_code = 'UBUNTU_12_64'
    subject.hardware_instance_template['operatingSystemReferenceCode'].should == 'UBUNTU_12_64'
  end

  it "places the attribute :hourly into the template as hourlyBillingFlag converting the value to a boolean constant" do
    # note, we don't want the flag to be nil we want it to be eotjer false or true
    subject.hardware_instance_template["hourlyBillingFlag"].should be(false)

    subject.hourly = true
    subject.hardware_instance_template["hourlyBillingFlag"].should be(true)

    subject.hourly = false
    subject.hardware_instance_template["hourlyBillingFlag"].should be(false)
  end

  it "puts the public VLAN id into an order template as primaryNetworkComponent.networkVlan.id" do
    subject.hardware_instance_template["primaryNetworkComponent"].should be_nil
    subject.public_vlan_id = 12345
    subject.hardware_instance_template["primaryNetworkComponent"].should == { "networkVlan" => { "id" => 12345 } }
  end

  it "puts the private VLAN id into an order template as primaryBackendNetworkComponent.networkVlan.id" do
    subject.hardware_instance_template["primaryBackendNetworkComponent"].should be_nil
    subject.private_vlan_id = 12345
    subject.hardware_instance_template["primaryBackendNetworkComponent"].should == { "networkVlan" => { "id" => 12345 } }
  end

  it "sets up disks in the order template as hardDrives" do
    subject.hardware_instance_template["hardDrives"].should be_nil
    subject.disks = [2, 25, 50]

    # note that device id 1 should be skipped as SoftLayer reserves that id for OS swap space.
    subject.hardware_instance_template["hardDrives"].should == [
      {"capacity"=>2},
      {"capacity"=>25},
      {"capacity"=>50}
    ]
  end

  it "puts the :ssh_key_ids in the template as sshKeys and breaks out the ids into objects" do
    subject.hardware_instance_template["sshKeys"].should be_nil
    subject.ssh_key_ids = [123, 456, 789]
    subject.hardware_instance_template['sshKeys'].should == [{'id' => 123}, {'id' => 456}, {'id' => 789}]
  end

  it "puts the :provision_script_URI property into the template as postInstallScriptUri" do
    subject.hardware_instance_template["postInstallScriptUri"].should be_nil
    subject.provision_script_URI = 'http:/provisionhome.mydomain.com/fancyscript.sh'
    subject.hardware_instance_template['postInstallScriptUri'].should == 'http:/provisionhome.mydomain.com/fancyscript.sh'
  end

  it "accepts URI objects for the provision script URI" do
    subject.hardware_instance_template["postInstallScriptUri"].should be_nil
    subject.provision_script_URI = URI.parse('http:/provisionhome.mydomain.com/fancyscript.sh')
    subject.hardware_instance_template['postInstallScriptUri'].should == 'http:/provisionhome.mydomain.com/fancyscript.sh'
  end

  it "places the private_network_only attribute in the template as privateNetworkOnlyFlag" do
    subject.hardware_instance_template["privateNetworkOnlyFlag"].should be_nil
    subject.private_network_only = true
    subject.hardware_instance_template["privateNetworkOnlyFlag"].should be_true
  end

  it "puts the user metadata string into the template as userData" do
    subject.hardware_instance_template["userData"].should be_nil
    subject.user_metadata = "MetadataValue"
    subject.hardware_instance_template['userData'].should == [{'value' => 'MetadataValue'}]
  end

  it "puts the max_port_speed attribute into the template as networkComponents.maxSpeed" do
    subject.hardware_instance_template["networkComponents"].should be_nil
    subject.max_port_speed = 1000
    subject.hardware_instance_template['networkComponents'].should == [{'maxSpeed' => 1000}]
  end

  it "calls the softlayer API to validate an order template" do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')

    test_order = SoftLayer::BareMetalServerOrder.new(client)
    test_order.cores = 2
    test_order.memory = 2
    test_order.hostname = "ruby-client-test"
    test_order.domain = "kitchentools.com"

    hardware_service = client["Hardware"]
    hardware_service.stub(:call_softlayer_api_with_params)

    expect(hardware_service).to receive(:generateOrderTemplate).with(test_order.hardware_instance_template)
    test_order.verify()
  end

  it "calls the softlayer API to place an order for a new virtual server" do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')

    test_order = SoftLayer::BareMetalServerOrder.new(client)
    test_order.cores = 2
    test_order.memory = 2
    test_order.hostname = "ruby-client-test"
    test_order.domain = "kitchentools.com"

    hardware_service = client["Hardware"]
    hardware_service.stub(:call_softlayer_api_with_params)

    expect(hardware_service).to receive(:createObject).with(test_order.hardware_instance_template)
    test_order.place_order!()
  end

  it "allows a block to modify the template sent to the server when verifying an order" do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')

    test_order = SoftLayer::BareMetalServerOrder.new(client)
    test_order.cores = 2
    test_order.memory = 2
    test_order.hostname = "ruby-client-test"
    test_order.domain = "kitchentools.com"

    hardware_service = client["Hardware"]
    hardware_service.stub(:call_softlayer_api_with_params)

    substituted_order_template = { 'aFake' => 'andBogusOrderTemplate' }
    expect(hardware_service).to receive(:generateOrderTemplate).with(substituted_order_template)
    test_order.verify() { |order_template| substituted_order_template }
  end

  it "allows a block to modify the template sent to the server when placing an order" do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')

    test_order = SoftLayer::BareMetalServerOrder.new(client)
    test_order.cores = 2
    test_order.memory = 2
    test_order.hostname = "ruby-client-test"
    test_order.domain = "kitchentools.com"

    hardware_service = client["Hardware"]
    hardware_service.stub(:call_softlayer_api_with_params)

    substituted_order_template = { 'aFake' => 'andBogusOrderTemplate' }
    expect(hardware_service).to receive(:createObject).with(substituted_order_template)
    test_order.place_order!() { |order_template| substituted_order_template }
  end

  describe "methods returning available options for attributes" do
    let (:client) do
      client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')
      virtual_guest_service = client["Hardware"]
      virtual_guest_service.stub(:call_softlayer_api_with_params)

      fake_options = fixture_from_json("Hardware_createObjectOptions")
      allow(virtual_guest_service).to receive(:getCreateObjectOptions) {
        fake_options
      }
      
      client
    end

    it "retrieves the set of options that can be put in the order template" do
      SoftLayer::BareMetalServerOrder.create_object_options(client).should == fixture_from_json("Hardware_createObjectOptions")
    end

    it "transmogrifies the datacenter options for the :datacenter attribute" do
      SoftLayer::BareMetalServerOrder.datacenter_options(client).should == ["ams01", "dal01", "dal05", "dal06", "sea01", "sjc01", "sng01", "wdc01"]
    end
    
    it "transmogrifies the processor create object options for the cores attribute" do
      SoftLayer::BareMetalServerOrder.core_options(client).should == [2, 4, 8, 16]
    end

    it "transmogrifies the blockDevices options for the disks attribute" do
      SoftLayer::BareMetalServerOrder.disk_options(client).should == [250, 500]
    end

    it "transmogrifies the operatingSystems create object options for the os_reference_code attribute" do
      SoftLayer::BareMetalServerOrder.os_reference_code_options(client).should == ["CENTOS_5_32", "CENTOS_5_64", "CENTOS_6_32", "CENTOS_6_64", "CLOUDLINUX_5_32", "CLOUDLINUX_5_64", "CLOUDLINUX_6_32", "CLOUDLINUX_6_64", "DEBIAN_6_32", "DEBIAN_6_64", "DEBIAN_7_32", "DEBIAN_7_64", "ESXI_5_64", "ESX_4_64", "FREEBSD_10_32", "FREEBSD_10_64", "FREEBSD_8_32", "FREEBSD_8_64", "FREEBSD_9_32", "FREEBSD_9_64", "REDHAT_5_32", "REDHAT_5_64", "REDHAT_6_32", "REDHAT_6_64", "UBUNTU_10_32", "UBUNTU_10_64", "UBUNTU_12_32", "UBUNTU_12_64", "UBUNTU_8_32", "UBUNTU_8_64", "VYATTACE_6.5R1_64", "VYATTACE_6.6R1_64", "VYATTASE_6.6R2_64", "WIN_2003-DC-SP2-1_32", "WIN_2003-DC-SP2-1_64", "WIN_2003-ENT-SP2-5_32", "WIN_2003-ENT-SP2-5_64", "WIN_2003-STD-SP2-5_32", "WIN_2003-STD-SP2-5_64", "WIN_2008-DC-R2_64", "WIN_2008-DC-SP2_32", "WIN_2008-DC-SP2_64", "WIN_2008-ENT-R2_64", "WIN_2008-ENT-SP2_32", "WIN_2008-ENT-SP2_64", "WIN_2008-STD-R2-SP1_64", "WIN_2008-STD-R2_64", "WIN_2008-STD-SP2_32", "WIN_2008-STD-SP2_64", "WIN_2012-DC_64", "WIN_2012-STD_64", "XENSERVER_5.5_64", "XENSERVER_5.6_64", "XENSERVER_6.0_64", "XENSERVER_6.1_64", "XENSERVER_6.2_64"]
    end

    it "transmogrifies the networkComponents create object options for the max_port_speed attribute" do
      SoftLayer::BareMetalServerOrder.max_port_speed_options(client).should == [10, 100, 1000]
    end
  end

end
