#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

describe SoftLayer::VLANFirewall do
  it "should have a class representing a firewall" do
    expect{ SoftLayer::VLANFirewall.new("not really a client", { "id" => 12345 }) }.to_not raise_error
  end

  describe "firewall rules bypass" do
    let(:mock_client) {
      mock_client = SoftLayer::Client.new(:username => "fake_user", :api_key => "BADKEY")
    }

    it "responds to the method change_routing_bypass!" do
      mock_firewall = SoftLayer::VLANFirewall.new("not really a client", { "id" => 12345 })
      expect(mock_firewall).to respond_to(:change_rules_bypass!)
    end

    it "accepts :apply_firewall_rules" do
      mock_firewall = SoftLayer::VLANFirewall.new(mock_client, { "id" => 12345, 'networkVlanFirewall' => {'id' => 67890}})
      allow(mock_firewall).to receive(:rules_ACL_id) { 0 }
      allow(mock_firewall).to receive(:rules) { {} }

      firewall_update_service = mock_client[:Network_Firewall_Update_Request]

      expect(firewall_update_service).to receive(:call_softlayer_api_with_params) do |method, parameters, arguments|
        expect(arguments[0]['bypassFlag']).to be(false)
      end

      mock_firewall.change_rules_bypass!(:apply_firewall_rules)
    end

    it "accepts :bypass_firewall_rules!" do
      mock_firewall = SoftLayer::VLANFirewall.new(mock_client, { "id" => 12345, 'networkVlanFirewall' => {'id' => 67890}})
      allow(mock_firewall).to receive(:rules_ACL_id) { 0 }
      allow(mock_firewall).to receive(:rules) { {} }

      firewall_update_service = mock_client[:Network_Firewall_Update_Request]
      expect(firewall_update_service).to receive(:call_softlayer_api_with_params) do |method, parameters, arguments|
        expect(arguments[0]['bypassFlag']).to be(true)
      end

      mock_firewall.change_rules_bypass!(:bypass_firewall_rules)
    end

    it "rejects other parameters (particularly true and false)" do
      mock_firewall = SoftLayer::VLANFirewall.new("not really a client", { "id" => 12345 })
      allow(mock_firewall).to receive(:rules) { {} }

      firewall_update_service = mock_client[:Network_Firewall_Update_Request]

      allow(firewall_update_service).to receive(:call_softlayer_api_with_params)

      expect{ mock_firewall.change_rules_bypass!(true) }.to raise_error(NoMethodError)
      expect{ mock_firewall.change_rules_bypass!(false) }.to raise_error(NoMethodError)
      expect{ mock_firewall.change_rules_bypass!(:route_around_firewall) }.to raise_error(NoMethodError)
      expect{ mock_firewall.change_rules_bypass!(:route_through_firewall) }.to raise_error(NoMethodError)
      expect{ mock_firewall.change_rules_bypass!("apply_firewall_rules") }.to raise_error(NoMethodError)
      expect{ mock_firewall.change_rules_bypass!("bypass_firewall_rules") }.to raise_error(NoMethodError)
      expect{ mock_firewall.change_rules_bypass!(nil) }.to raise_error(NoMethodError)
      expect{ mock_firewall.change_rules_bypass!(1) }.to raise_error(NoMethodError)
      expect{ mock_firewall.change_rules_bypass!(0) }.to raise_error(NoMethodError)
    end
  end

  describe "firewall routing changes" do
    let(:mock_client) {
      mock_client = SoftLayer::Client.new(:username => "fake_user", :api_key => "BADKEY")
    }

    it "responds to the method change_routing_bypass!" do
      mock_firewall = SoftLayer::VLANFirewall.new("not really a client", { "id" => 12345 })
      expect(mock_firewall).to respond_to(:change_routing_bypass!)
    end

    it "accepts :route_through_firewall" do
      mock_firewall = SoftLayer::VLANFirewall.new(mock_client, { "id" => 12345, 'networkVlanFirewall' => {'id' => 67890}})
      allow(mock_firewall).to receive(:rules_ACL_id) { 0 }
      vlan_firewall_service = mock_client[:Network_Vlan_Firewall]

      expect(vlan_firewall_service).to receive(:call_softlayer_api_with_params).with(:updateRouteBypass,an_instance_of(SoftLayer::APIParameterFilter),[false])
      mock_firewall.change_routing_bypass!(:route_through_firewall)
    end

    it "accepts :route_around_firewall" do
      mock_firewall = SoftLayer::VLANFirewall.new(mock_client, { "id" => 12345, 'networkVlanFirewall' => {'id' => 67890}})
      allow(mock_firewall).to receive(:rules_ACL_id) { 0 }
      vlan_firewall_service = mock_client[:Network_Vlan_Firewall]

      expect(vlan_firewall_service).to receive(:call_softlayer_api_with_params).with(:updateRouteBypass,an_instance_of(SoftLayer::APIParameterFilter),[true])
      mock_firewall.change_routing_bypass!(:route_around_firewall)
    end

    it "rejects other parameters (particularly true and false)" do
      mock_firewall = SoftLayer::VLANFirewall.new("not really a client", { "id" => 12345 })
      allow(mock_firewall).to receive(:rules_ACL_id) { 0 }

      vlan_firewall_service = mock_client[:Network_Vlan_Firewall]

      allow(vlan_firewall_service).to receive(:call_softlayer_api_with_params)

      expect{ mock_firewall.change_routing_bypass!(true) }.to raise_error(NoMethodError)
      expect{ mock_firewall.change_routing_bypass!(false) }.to raise_error(NoMethodError)
      expect{ mock_firewall.change_routing_bypass!(:apply_firewall_rules) }.to raise_error(NoMethodError)
      expect{ mock_firewall.change_routing_bypass!(:bypass_firewall_rules) }.to raise_error(NoMethodError)
      expect{ mock_firewall.change_routing_bypass!("route_around_firewall") }.to raise_error(NoMethodError)
      expect{ mock_firewall.change_routing_bypass!("route_through_firewall") }.to raise_error(NoMethodError)
      expect{ mock_firewall.change_routing_bypass!(nil) }.to raise_error(NoMethodError)
      expect{ mock_firewall.change_routing_bypass!(1) }.to raise_error(NoMethodError)
      expect{ mock_firewall.change_routing_bypass!(0) }.to raise_error(NoMethodError)
    end
  end
end
