#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

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

  it "allows creation using the default client" do
    SoftLayer::Client.default_client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')
    order = SoftLayer::BareMetalServerOrder.new()
    expect(order.instance_eval{ @softlayer_client}).to be(SoftLayer::Client.default_client)
    SoftLayer::Client.default_client = nil
  end

  it "raises an error if you try to create an order with no client" do
    SoftLayer::Client.default_client = nil
    expect {SoftLayer::BareMetalServerOrder.new()}.to raise_error
  end

  it "places its :datacenter attribute into the order template" do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')

    expect(subject.hardware_instance_template["datacenter"]).to be_nil
    subject.datacenter = SoftLayer::Datacenter.new(client, 'id' => 42, 'name' => "dal05")
    expect(subject.hardware_instance_template["datacenter"]).to eq({ "name" => "dal05" })
  end

  it "places its :hostname attribute into the order template" do
    expect(subject.hardware_instance_template["hostname"]).to be_nil
    subject.hostname = "testhostname"
    expect(subject.hardware_instance_template["hostname"]).to eq "testhostname"
  end

  it "places its :domain attribute into the order template" do
    expect(subject.hardware_instance_template["domain"]).to be_nil
    subject.domain = "softlayer.com"
    expect(subject.hardware_instance_template["domain"]).to eq "softlayer.com"
  end

  it "places its :cores attribute into the order template as startCpus" do
    subject.cores = 4
    expect(subject.hardware_instance_template["processorCoreAmount"]).to eq 4
  end

  it "places the :memory attrbute in the template as memoryCapacity" do
    subject.memory = 4
    expect(subject.hardware_instance_template["memoryCapacity"]).to eq 4
  end

  it "places an OS identifier into the order template as the operatingSystemReferenceCode" do
    expect(subject.hardware_instance_template["operatingSystemReferenceCode"]).to be_nil
    subject.os_reference_code = 'UBUNTU_12_64'
    expect(subject.hardware_instance_template['operatingSystemReferenceCode']).to eq 'UBUNTU_12_64'
  end

  it "places the attribute :hourly into the template as hourlyBillingFlag converting the value to a boolean constant" do
    # note, we don't want the flag to be nil we want it to be eotjer false or true
    expect(subject.hardware_instance_template["hourlyBillingFlag"]).to be(false)

    subject.hourly = true
    expect(subject.hardware_instance_template["hourlyBillingFlag"]).to be(true)

    subject.hourly = false
    expect(subject.hardware_instance_template["hourlyBillingFlag"]).to be(false)
  end

  it "puts the public VLAN id into an order template as primaryNetworkComponent.networkVlan.id" do
    expect(subject.hardware_instance_template["primaryNetworkComponent"]).to be_nil
    subject.public_vlan_id = 12345
    expect(subject.hardware_instance_template["primaryNetworkComponent"]).to eq({ "networkVlan" => { "id" => 12345 } })
  end

  it "puts the private VLAN id into an order template as primaryBackendNetworkComponent.networkVlan.id" do
    expect(subject.hardware_instance_template["primaryBackendNetworkComponent"]).to be_nil
    subject.private_vlan_id = 12345
    expect(subject.hardware_instance_template["primaryBackendNetworkComponent"]).to eq({ "networkVlan" => { "id" => 12345 } })
  end

  it "sets up disks in the order template as hardDrives" do
    expect(subject.hardware_instance_template["hardDrives"]).to be_nil
    subject.disks = [2, 25, 50]

    # note that device id 1 should be skipped as SoftLayer reserves that id for OS swap space.
    expect(subject.hardware_instance_template["hardDrives"]).to eq [
      {"capacity"=>2},
      {"capacity"=>25},
      {"capacity"=>50}
    ]
  end

  it "puts the :ssh_key_ids in the template as sshKeys and breaks out the ids into objects" do
    expect(subject.hardware_instance_template["sshKeys"]).to be_nil
    subject.ssh_key_ids = [123, 456, 789]
    expect(subject.hardware_instance_template['sshKeys']).to eq [{'id' => 123}, {'id' => 456}, {'id' => 789}]
  end

  it "puts the :provision_script_URI property into the template as postInstallScriptUri" do
    expect(subject.hardware_instance_template["postInstallScriptUri"]).to be_nil
    subject.provision_script_URI = 'http:/provisionhome.mydomain.com/fancyscript.sh'
    expect(subject.hardware_instance_template['postInstallScriptUri']).to eq 'http:/provisionhome.mydomain.com/fancyscript.sh'
  end

  it "accepts URI objects for the provision script URI" do
    expect(subject.hardware_instance_template["postInstallScriptUri"]).to be_nil
    subject.provision_script_URI = URI.parse('http:/provisionhome.mydomain.com/fancyscript.sh')
    expect(subject.hardware_instance_template['postInstallScriptUri']).to eq 'http:/provisionhome.mydomain.com/fancyscript.sh'
  end

  it "places the private_network_only attribute in the template as privateNetworkOnlyFlag" do
    expect(subject.hardware_instance_template["privateNetworkOnlyFlag"]).to be_nil
    subject.private_network_only = true
    expect(subject.hardware_instance_template["privateNetworkOnlyFlag"]).to be(true)
  end

  it "puts the user metadata string into the template as userData" do
    expect(subject.hardware_instance_template["userData"]).to be_nil
    subject.user_metadata = "MetadataValue"
    expect(subject.hardware_instance_template['userData']).to eq [{'value' => 'MetadataValue'}]
  end

  it "puts the max_port_speed attribute into the template as networkComponents.maxSpeed" do
    expect(subject.hardware_instance_template["networkComponents"]).to be_nil
    subject.max_port_speed = 1000
    expect(subject.hardware_instance_template['networkComponents']).to eq [{'maxSpeed' => 1000}]
  end

  it "calls the softlayer API to validate an order template" do
    client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')

    test_order = SoftLayer::BareMetalServerOrder.new(client)
    test_order.cores = 2
    test_order.memory = 2
    test_order.hostname = "ruby-client-test"
    test_order.domain = "kitchentools.com"

    hardware_service = client["Hardware"]
    allow(hardware_service).to receive(:call_softlayer_api_with_params)

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
    allow(hardware_service).to receive(:call_softlayer_api_with_params)

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
    allow(hardware_service).to receive(:call_softlayer_api_with_params)

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
    allow(hardware_service).to receive(:call_softlayer_api_with_params)

    substituted_order_template = { 'aFake' => 'andBogusOrderTemplate' }
    expect(hardware_service).to receive(:createObject).with(substituted_order_template)
    test_order.place_order!() { |order_template| substituted_order_template }
  end

  describe "methods returning available options for attributes" do
    let (:client) do
      client = SoftLayer::Client.new(:username => "fakeusername", :api_key => 'DEADBEEFBADF00D')
      virtual_guest_service = client["Hardware"]
      allow(virtual_guest_service).to receive(:call_softlayer_api_with_params)
      fake_options =
      allow(virtual_guest_service).to receive(:getCreateObjectOptions) { fixture_from_json("Hardware_createObjectOptions") }

      location_service = client[:Location]
      allow(location_service).to receive(:call_softlayer_api_with_params)
      allow(location_service).to receive(:getDatacenters) {fixture_from_json("datacenter_locations")}

      client
    end

    it "retrieves the set of options that can be put in the order template" do
      expect(SoftLayer::BareMetalServerOrder.create_object_options(client)).to eq(fixture_from_json("Hardware_createObjectOptions"))
    end

    it "transmogrifies the datacenter options for the :datacenter attribute" do
      datacenter_options = SoftLayer::BareMetalServerOrder.datacenter_options(client)
      datacenter_names = datacenter_options.map { |datacenter| datacenter.name }.sort
      expect(datacenter_names).to eq ["ams01", "dal01", "dal05", "dal06", "sea01", "sjc01", "sng01", "wdc01"]
    end

    it "transmogrifies the processor create object options for the cores attribute" do
      expect(SoftLayer::BareMetalServerOrder.core_options(client)).to eq [2, 4, 8, 16]
    end

    it "transmogrifies the blockDevices options for the disks attribute" do
      expect(SoftLayer::BareMetalServerOrder.disk_options(client)).to eq [250, 500]
    end

    it "transmogrifies the operatingSystems create object options for the os_reference_code attribute" do
      expect(SoftLayer::BareMetalServerOrder.os_reference_code_options(client)).to eq ["CENTOS_5_32", "CENTOS_5_64", "CENTOS_6_32", "CENTOS_6_64", "CLOUDLINUX_5_32", "CLOUDLINUX_5_64", "CLOUDLINUX_6_32", "CLOUDLINUX_6_64", "DEBIAN_6_32", "DEBIAN_6_64", "DEBIAN_7_32", "DEBIAN_7_64", "ESXI_5_64", "ESX_4_64", "FREEBSD_10_32", "FREEBSD_10_64", "FREEBSD_8_32", "FREEBSD_8_64", "FREEBSD_9_32", "FREEBSD_9_64", "REDHAT_5_32", "REDHAT_5_64", "REDHAT_6_32", "REDHAT_6_64", "UBUNTU_10_32", "UBUNTU_10_64", "UBUNTU_12_32", "UBUNTU_12_64", "UBUNTU_8_32", "UBUNTU_8_64", "VYATTACE_6.5R1_64", "VYATTACE_6.6R1_64", "VYATTASE_6.6R2_64", "WIN_2003-DC-SP2-1_32", "WIN_2003-DC-SP2-1_64", "WIN_2003-ENT-SP2-5_32", "WIN_2003-ENT-SP2-5_64", "WIN_2003-STD-SP2-5_32", "WIN_2003-STD-SP2-5_64", "WIN_2008-DC-R2_64", "WIN_2008-DC-SP2_32", "WIN_2008-DC-SP2_64", "WIN_2008-ENT-R2_64", "WIN_2008-ENT-SP2_32", "WIN_2008-ENT-SP2_64", "WIN_2008-STD-R2-SP1_64", "WIN_2008-STD-R2_64", "WIN_2008-STD-SP2_32", "WIN_2008-STD-SP2_64", "WIN_2012-DC_64", "WIN_2012-STD_64", "XENSERVER_5.5_64", "XENSERVER_5.6_64", "XENSERVER_6.0_64", "XENSERVER_6.1_64", "XENSERVER_6.2_64"]
    end

    it "transmogrifies the networkComponents create object options for the max_port_speed attribute" do
      expect(SoftLayer::BareMetalServerOrder.max_port_speed_options(client)).to eq [10, 100, 1000]
    end

    it "has options routines that can use the default client" do
      SoftLayer::Client.default_client = client
      expect { SoftLayer::BareMetalServerOrder.create_object_options() }.to_not raise_error
      expect { SoftLayer::BareMetalServerOrder.datacenter_options() }.to_not raise_error
      expect { SoftLayer::BareMetalServerOrder.core_options() }.to_not raise_error
      expect { SoftLayer::BareMetalServerOrder.disk_options() }.to_not raise_error
      expect { SoftLayer::BareMetalServerOrder.os_reference_code_options() }.to_not raise_error
      expect { SoftLayer::BareMetalServerOrder.max_port_speed_options() }.to_not raise_error
    end

    it "has options routines that raise if not given a client" do
      SoftLayer::Client.default_client = nil
      expect { SoftLayer::BareMetalServerOrder.create_object_options() }.to raise_error
      expect { SoftLayer::BareMetalServerOrder.datacenter_options() }.to raise_error
      expect { SoftLayer::BareMetalServerOrder.core_options() }.to raise_error
      expect { SoftLayer::BareMetalServerOrder.disk_options() }.to raise_error
      expect { SoftLayer::BareMetalServerOrder.os_reference_code_options() }.to raise_error
      expect { SoftLayer::BareMetalServerOrder.max_port_speed_options() }.to raise_error
    end
  end

end
