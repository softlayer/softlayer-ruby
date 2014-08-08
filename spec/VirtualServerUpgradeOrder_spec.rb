#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

describe SoftLayer::VirtualServerUpgradeOrder do
  before(:each) do
    SoftLayer::VirtualServerUpgradeOrder.send(:public, *SoftLayer::VirtualServerUpgradeOrder.private_instance_methods)
  end

  let(:test_virtual_server) do
		mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "DEADBEEFBADF00D")
    virtual_guest_service = mock_client[:Virtual_Guest]
    allow(virtual_guest_service).to receive(:call_softlayer_api_with_params) do |api_method, parameters, api_arguments|
      api_return = nil

      case api_method
      when :getUpgradeItemPrices
        api_return = fixture_from_json('virtual_server_upgrade_options')
      else
        fail "Unexpected call to the SoftLayer_Virtual_Guest service"
      end

      api_return
    end

    test_servers = fixture_from_json('test_virtual_servers')
    SoftLayer::VirtualServer.new(mock_client, test_servers.first)
  end

  it "requires a virtual server when initialized" do
    expect { SoftLayer::VirtualServerUpgradeOrder.new(nil) }.to raise_error
    expect { SoftLayer::VirtualServerUpgradeOrder.new("foo") }.to raise_error
    expect { SoftLayer::VirtualServerUpgradeOrder.new(test_virtual_server) }.to_not raise_error
  end

  it "initializes with none of the upgrades specified" do
    upgrade_order = SoftLayer::VirtualServerUpgradeOrder.new(test_virtual_server)
    expect(upgrade_order.cores == nil)
    expect(upgrade_order.ram == nil)
    expect(upgrade_order.max_port_speed == nil)
    expect(upgrade_order.upgrade_at == nil)
  end

  it "identifies what options are available for upgrading the number of cores" do
    sample_order = SoftLayer::VirtualServerUpgradeOrder.new(test_virtual_server)
    expect(sample_order.core_options).to eq [1, 2, 4, 8, 12, 16]
  end

  it "identifies what options are available for upgrading ram" do
    sample_order = SoftLayer::VirtualServerUpgradeOrder.new(test_virtual_server)
    expect(sample_order.memory_options).to eq [1, 2, 4, 6, 8, 12, 16, 32, 48, 64]
  end

  it "identifies what options are available for upgrading max port speed" do
    sample_order = SoftLayer::VirtualServerUpgradeOrder.new(test_virtual_server)
    expect(sample_order.max_port_speed_options).to eq [10, 100, 1000]
  end

  it "places the number of cores asked for into the order template" do
    sample_order = SoftLayer::VirtualServerUpgradeOrder.new(test_virtual_server)
    sample_order.core_options.each do |num_cores|
      sample_order.cores = num_cores
      test_template = sample_order.order_object
      expect(sample_order.order_object["prices"].length).to be(1)

      item = sample_order._item_price_with_capacity("guest_core", num_cores)
      expect(test_template["prices"].first["id"]).to eq item["id"]
    end
  end

  it "places the amount of RAM asked for into the order template" do
    sample_order = SoftLayer::VirtualServerUpgradeOrder.new(test_virtual_server)
    sample_order.memory_options.each do |ram_in_GB|
      sample_order.ram = ram_in_GB
      test_template = sample_order.order_object
      expect(sample_order.order_object["prices"].length).to be(1)

      item = sample_order._item_price_with_capacity("ram", ram_in_GB)
      expect(test_template["prices"].first["id"]).to eq item["id"]
    end
  end

  it "places the port speed asked for into the order template" do
    sample_order = SoftLayer::VirtualServerUpgradeOrder.new(test_virtual_server)
    sample_order.max_port_speed_options.each do |port_speed|
      sample_order.max_port_speed = port_speed
      test_template = sample_order.order_object
      expect(sample_order.order_object["prices"].length).to be(1)

      item = sample_order._item_price_with_capacity("port_speed", port_speed)
      expect(test_template["prices"].first["id"]).to eq item["id"]
    end
  end

  it "adds the default maintenance window of 'now' if none is given" do
    sample_order = SoftLayer::VirtualServerUpgradeOrder.new(test_virtual_server)
    sample_order.cores = 2
    test_template = sample_order.order_object

    expect(sample_order.order_object["properties"].first["name"]).to eq('MAINTENANCE_WINDOW')

    time_string = sample_order.order_object["properties"].first["value"]
    maintenance_time = Time.iso8601(time_string)

    expect((Time.now - maintenance_time) <= 1.0).to be(true)
  end

  it "adds the appointed maintenance window one is given" do
    sample_order = SoftLayer::VirtualServerUpgradeOrder.new(test_virtual_server)
    sample_order.cores = 2

    upgrade_time = Time.now + 3600  # in an hour
    sample_order.upgrade_at = upgrade_time

    test_template = sample_order.order_object

    expect(sample_order.order_object["properties"].first["name"]).to eq('MAINTENANCE_WINDOW')

    time_string = sample_order.order_object["properties"].first["value"]
    expect(time_string).to eq upgrade_time.iso8601
  end

  it "verifies product orders" do
    product_order_service = test_virtual_server.softlayer_client[:Product_Order]

    sample_order = SoftLayer::VirtualServerUpgradeOrder.new(test_virtual_server)
    sample_order.cores = 2

    order_object = sample_order.order_object
    expect(product_order_service).to receive(:call_softlayer_api_with_params).with(:verifyOrder, anything, [order_object])

    sample_order.verify()
  end

  it "places product orders" do
    product_order_service = test_virtual_server.softlayer_client[:Product_Order]

    sample_order = SoftLayer::VirtualServerUpgradeOrder.new(test_virtual_server)
    sample_order.cores = 2

    order_object = sample_order.order_object
    expect(product_order_service).to receive(:call_softlayer_api_with_params).with(:placeOrder, anything, [order_object])

    sample_order.place_order!()
  end
end