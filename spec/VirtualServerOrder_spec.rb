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

describe SoftLayer::VirtualServerOrder do
  before(:each) do
    SoftLayer::VirtualServerOrder.send(:public, *SoftLayer::VirtualServerOrder.protected_instance_methods)
  end

  let (:subject) do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')
    SoftLayer::VirtualServerOrder.new(client)
  end

  it "allows creation using the default client" do
    SoftLayer::Client.default_client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')
    order = SoftLayer::VirtualServerOrder.new()
    expect(order.instance_eval{ @softlayer_client}).to be(SoftLayer::Client.default_client)
    SoftLayer::Client.default_client = nil
  end

  it "raises an error if you try to create an order with no client" do
    SoftLayer::Client.default_client = nil
    expect {SoftLayer::VirtualServerOrder.new()}.to raise_error
  end

  it "places its :datacenter attribute into the order template" do
    expect(subject.virtual_guest_template["datacenter"]).to be_nil
    subject.datacenter = "dal05"
    expect(subject.virtual_guest_template["datacenter"]).to eq({ "name" => "dal05" })
  end

  it "places its :hostname attribute into the order template" do
    expect(subject.virtual_guest_template["hostname"]).to be_nil
    subject.hostname = "testhostname"
    expect(subject.virtual_guest_template["hostname"]).to eq "testhostname"
  end

  it "places its :domain attribute into the order template" do
    expect(subject.virtual_guest_template["domain"]).to be_nil
    subject.domain = "softlayer.com"
    expect(subject.virtual_guest_template["domain"]).to eq "softlayer.com"
  end

  it "places its :cores attribute into the order template as startCpus" do
    subject.cores = 4
    expect(subject.virtual_guest_template["startCpus"]).to eq 4
  end

  it "places the MB value of the :memory attrbute in the template as maxMemory" do
    subject.memory = 4
    expect(subject.virtual_guest_template["maxMemory"]).to eq 4096
  end

  it "places an OS identifier into the order template as the operatingSystemReferenceCode" do
    expect(subject.virtual_guest_template["operatingSystemReferenceCode"]).to be_nil
    subject.os_reference_code = 'UBUNTU_12_64'
    expect(subject.virtual_guest_template['operatingSystemReferenceCode']).to eq 'UBUNTU_12_64'
  end

  it "places an image template global identifier in the template as blockDeviceTemplateGroup.globalIdentifier" do
    expect(subject.virtual_guest_template["blockDeviceTemplateGroup"]).to be_nil
    subject.image_global_id = "12345-abcd-eatatjoes"
    expect(subject.virtual_guest_template['blockDeviceTemplateGroup']).to eq({'globalIdentifier' => '12345-abcd-eatatjoes'})
  end

  it "allows an image global id to override an os reference code when both are provided" do
    expect(subject.virtual_guest_template["blockDeviceTemplateGroup"]).to be_nil
    expect(subject.virtual_guest_template["operatingSystemReferenceCode"]).to be_nil

    subject.image_global_id = "12345-abcd-eatatjoes"
    subject.os_reference_code = 'UBUNTU_12_64'

    expect(subject.virtual_guest_template['blockDeviceTemplateGroup']).to eq({'globalIdentifier' => '12345-abcd-eatatjoes'})
    expect(subject.virtual_guest_template['operatingSystemReferenceCode']).to be_nil
  end

  it "places the attribute :hourly into the template as hourlyBillingFlag converting the value to a boolean constant" do
    # note, we don't want the flag to be nil we want it to be eotjer false or true
    expect(subject.virtual_guest_template["hourlyBillingFlag"]).to be(false)

    subject.hourly = true
    expect(subject.virtual_guest_template["hourlyBillingFlag"]).to be(true)

    subject.hourly = false
    expect(subject.virtual_guest_template["hourlyBillingFlag"]).to be(false)
  end

  it "places the attribute :use_local_disk in the template as the localDiskFlag" do
    # note, we don't want the flag to be nil we want it to be false or true
    expect(subject.virtual_guest_template["localDiskFlag"]).to be(false)

    subject.use_local_disk = true
    expect(subject.virtual_guest_template["localDiskFlag"]).to be(true)

    subject.use_local_disk = false
    expect(subject.virtual_guest_template["localDiskFlag"]).to be(false)
  end

  it "places the attribute :dedicated_host_only in the template as dedicatedAccountHostOnlyFlag" do
    expect(subject.virtual_guest_template["dedicatedAccountHostOnlyFlag"]).to be_nil
    subject.dedicated_host_only = true
    expect(subject.virtual_guest_template["dedicatedAccountHostOnlyFlag"]).to be(true)
  end

  it "puts the public VLAN id into an order template as primaryNetworkComponent.networkVlan.id" do
    expect(subject.virtual_guest_template["primaryNetworkComponent"]).to be_nil
    subject.public_vlan_id = 12345
    expect(subject.virtual_guest_template["primaryNetworkComponent"]).to eq({ "networkVlan" => { "id" => 12345 } })
  end

  it "puts the private VLAN id into an order template as primaryBackendNetworkComponent.networkVlan.id" do
    expect(subject.virtual_guest_template["primaryBackendNetworkComponent"]).to be_nil
    subject.private_vlan_id = 12345
    expect(subject.virtual_guest_template["primaryBackendNetworkComponent"]).to eq({ "networkVlan" => { "id" => 12345 } })
  end

  it "sets up disks in the order template as blockDevices" do
    expect(subject.virtual_guest_template["blockDevices"]).to be_nil
    subject.disks = [2, 25, 50]

    # note that device id 1 should be skipped as SoftLayer reserves that id for OS swap space.
    expect(subject.virtual_guest_template["blockDevices"]).to eq [
      {"device"=>"0", "diskImage"=>{"capacity"=>2}},
      {"device"=>"2", "diskImage"=>{"capacity"=>25}},
      {"device"=>"3", "diskImage"=>{"capacity"=>50}}
    ]
  end

  it "puts the :ssh_key_ids in the template as sshKeys and breaks out the ids into objects" do
    expect(subject.virtual_guest_template["sshKeys"]).to be_nil
    subject.ssh_key_ids = [123, 456, 789]
    expect(subject.virtual_guest_template['sshKeys']).to eq [{'id' => 123}, {'id' => 456}, {'id' => 789}]
  end

  it "puts the :provision_script_URI property into the template as postInstallScriptUri" do
    expect(subject.virtual_guest_template["postInstallScriptUri"]).to be_nil
    subject.provision_script_URI = 'http:/provisionhome.mydomain.com/fancyscript.sh'
    expect(subject.virtual_guest_template['postInstallScriptUri']).to eq 'http:/provisionhome.mydomain.com/fancyscript.sh'
  end

  it "accepts URI objects for the provision script URI" do
    expect(subject.virtual_guest_template["postInstallScriptUri"]).to be_nil
    subject.provision_script_URI = URI.parse('http:/provisionhome.mydomain.com/fancyscript.sh')
    expect(subject.virtual_guest_template['postInstallScriptUri']).to eq 'http:/provisionhome.mydomain.com/fancyscript.sh'
  end

  it "places the private_network_only attribute in the template as privateNetworkOnlyFlag" do
    expect(subject.virtual_guest_template["privateNetworkOnlyFlag"]).to be_nil
    subject.private_network_only = true
    expect(subject.virtual_guest_template["privateNetworkOnlyFlag"]).to be(true)
  end

  it "puts the user metadata string into the template as userData" do
    expect(subject.virtual_guest_template["userData"]).to be_nil
    subject.user_metadata = "MetadataValue"
    expect(subject.virtual_guest_template['userData']).to eq [{'value' => 'MetadataValue'}]
  end

  it "puts the max_port_speed attribute into the template as networkComponents.maxSpeed" do
    expect(subject.virtual_guest_template["networkComponents"]).to be_nil
    subject.max_port_speed = 1000
    expect(subject.virtual_guest_template['networkComponents']).to eq [{'maxSpeed' => 1000}]
  end

  it "calls the softlayer API to validate an order template" do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')

    test_order = SoftLayer::VirtualServerOrder.new(client)
    test_order.cores = 2
    test_order.memory = 2
    test_order.hostname = "ruby-client-test"
    test_order.domain = "kitchentools.com"

    virtual_guest_service = client["Virtual_Guest"]
    allow(virtual_guest_service).to receive(:call_softlayer_api_with_params)

    expect(virtual_guest_service).to receive(:generateOrderTemplate).with(test_order.virtual_guest_template)
    test_order.verify()
  end

  it "calls the softlayer API to place an order for a new virtual server" do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')

    test_order = SoftLayer::VirtualServerOrder.new(client)
    test_order.cores = 2
    test_order.memory = 2
    test_order.hostname = "ruby-client-test"
    test_order.domain = "kitchentools.com"

    virtual_guest_service = client["Virtual_Guest"]
    allow(virtual_guest_service).to receive(:call_softlayer_api_with_params)

    expect(virtual_guest_service).to receive(:createObject).with(test_order.virtual_guest_template)
    test_order.place_order!()
  end

  it "allows a block to modify the template sent to the server when verifying an order" do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')

    test_order = SoftLayer::VirtualServerOrder.new(client)
    test_order.cores = 2
    test_order.memory = 2
    test_order.hostname = "ruby-client-test"
    test_order.domain = "kitchentools.com"

    virtual_guest_service = client["Virtual_Guest"]
    allow(virtual_guest_service).to receive(:call_softlayer_api_with_params)

    substituted_order_template = { 'aFake' => 'andBogusOrderTemplate' }
    expect(virtual_guest_service).to receive(:generateOrderTemplate).with(substituted_order_template)
    test_order.verify() { |order_template| substituted_order_template }
  end

  it "allows a block to modify the template sent to the server when placing an order" do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')

    test_order = SoftLayer::VirtualServerOrder.new(client)
    test_order.cores = 2
    test_order.memory = 2
    test_order.hostname = "ruby-client-test"
    test_order.domain = "kitchentools.com"

    virtual_guest_service = client["Virtual_Guest"]
    allow(virtual_guest_service).to receive(:call_softlayer_api_with_params)

    substituted_order_template = { 'aFake' => 'andBogusOrderTemplate' }
    expect(virtual_guest_service).to receive(:createObject).with(substituted_order_template)
    test_order.place_order!() { |order_template| substituted_order_template }
  end

  describe "methods returning available options for attributes" do
    let (:client) do
      client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')
      virtual_guest_service = client["Virtual_Guest"]
      allow(virtual_guest_service).to receive(:call_softlayer_api_with_params)

      fake_options = fixture_from_json("Virtual_Guest_createObjectOptions")
      allow(virtual_guest_service).to receive(:getCreateObjectOptions) {
        fake_options
      }

      client
    end

    after (:each) do
      SoftLayer::Client.default_client = nil
    end

    it "retrieves the set of options that can be put in the order template" do
      fake_options = fixture_from_json("Virtual_Guest_createObjectOptions")
      expect(SoftLayer::VirtualServerOrder.create_object_options(client)).to eq fake_options
    end

    it "transmogrifies the datacenter options for the cores attribute" do
      expect(SoftLayer::VirtualServerOrder.datacenter_options(client)).to eq ["ams01", "dal01", "dal05", "dal06", "sea01", "sjc01", "sng01", "wdc01"]
    end

    it "transmogrifies the processor options for the cores attribute" do
      expect(SoftLayer::VirtualServerOrder.core_options(client)).to eq [1, 2, 4, 8, 12, 16]
    end

    it "transmogrifies the memory options for the memory attribute" do
      expect(SoftLayer::VirtualServerOrder.memory_options(client)).to eq [1, 2, 4, 6, 8, 12, 16, 32, 48, 64]
    end

    it "transmogrifies the blockDevices options for the disks attribute" do
      expect(SoftLayer::VirtualServerOrder.disk_options(client)).to eq [10, 20, 25, 30, 40, 50, 75, 100, 125, 150, 175, 200, 250, 300, 350, 400, 500, 750, 1000, 1500, 2000]
    end

    it "transmogrifies the operatingSystems options for the os_reference_code attribute" do
      expect(SoftLayer::VirtualServerOrder.os_reference_code_options(client)).to eq ["CENTOS_5_32", "CENTOS_5_64", "CENTOS_6_32", "CENTOS_6_64", "CLOUDLINUX_5_32", "CLOUDLINUX_5_64", "CLOUDLINUX_6_32", "CLOUDLINUX_6_64", "DEBIAN_5_32", "DEBIAN_5_64", "DEBIAN_6_32", "DEBIAN_6_64", "DEBIAN_7_32", "DEBIAN_7_64", "REDHAT_5_32", "REDHAT_5_64", "REDHAT_6_32", "REDHAT_6_64", "UBUNTU_10_32", "UBUNTU_10_64", "UBUNTU_12_32", "UBUNTU_12_64", "UBUNTU_8_32", "UBUNTU_8_64", "VYATTACE_6.5_64", "VYATTACE_6.6_64", "WIN_2003-DC-SP2-1_32", "WIN_2003-DC-SP2-1_64", "WIN_2003-ENT-SP2-5_32", "WIN_2003-ENT-SP2-5_64", "WIN_2003-STD-SP2-5_32", "WIN_2003-STD-SP2-5_64", "WIN_2008-DC-R2_64", "WIN_2008-DC-SP2_64", "WIN_2008-ENT-R2_64", "WIN_2008-ENT-SP2_32", "WIN_2008-ENT-SP2_64", "WIN_2008-STD-R2-SP1_64", "WIN_2008-STD-R2_64", "WIN_2008-STD-SP2_32", "WIN_2008-STD-SP2_64", "WIN_2012-DC_64", "WIN_2012-STD_64"]
    end

    it "transmogrifies the networkComponents options for the max_port_speed attribute" do
      expect(SoftLayer::VirtualServerOrder.max_port_speed_options(client)).to eq [10, 100, 1000]
    end

    it "has options routines that can use the default client" do
      SoftLayer::Client.default_client = client
      expect { SoftLayer::VirtualServerOrder.create_object_options() }.to_not raise_error
      expect { SoftLayer::VirtualServerOrder.datacenter_options() }.to_not raise_error
      expect { SoftLayer::VirtualServerOrder.create_object_options() }.to_not raise_error
      expect { SoftLayer::VirtualServerOrder.core_options() }.to_not raise_error
      expect { SoftLayer::VirtualServerOrder.memory_options() }.to_not raise_error
      expect { SoftLayer::VirtualServerOrder.disk_options() }.to_not raise_error
      expect { SoftLayer::VirtualServerOrder.os_reference_code_options() }.to_not raise_error
      expect { SoftLayer::VirtualServerOrder.max_port_speed_options() }.to_not raise_error
    end

    it "has options routines that raise if not given a client" do
      SoftLayer::Client.default_client = nil
      expect { SoftLayer::VirtualServerOrder.create_object_options() }.to raise_error
      expect { SoftLayer::VirtualServerOrder.datacenter_options() }.to raise_error
      expect { SoftLayer::VirtualServerOrder.create_object_options() }.to raise_error
      expect { SoftLayer::VirtualServerOrder.core_options() }.to raise_error
      expect { SoftLayer::VirtualServerOrder.memory_options() }.to raise_error
      expect { SoftLayer::VirtualServerOrder.disk_options() }.to raise_error
      expect { SoftLayer::VirtualServerOrder.os_reference_code_options() }.to raise_error
      expect { SoftLayer::VirtualServerOrder.max_port_speed_options() }.to raise_error
    end
  end
end
