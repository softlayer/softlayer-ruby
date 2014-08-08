#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
	class VLANFirewall < SoftLayer::ModelBase
    sl_attr :VLAN_number, 'vlanNumber'

    ##
    # return the name of the router the firewall is attached to
    def primaryRouter
      return self['primaryRouter']['hostname']
    end

    ##
    # The fully qualified domain name of the firewall
    def fullyQualifiedDomainName
      if self.has_sl_property?('networkVlanFirewall')
        return self['networkVlanFirewall']['fullyQualifiedDomainName']
      else
        return @softlayer_hash
      end
    end

    ##
    # returns true if the firewall has the high availability flag set
    #
    def high_availability?
      # note that highAvailabilityFirewallFlag is a boolean in the softlayer hash
      return self.has_sl_property?('highAvailabilityFirewallFlag') && self['highAvailabilityFirewallFlag']
    end

    def rule_set
      rule_set = nil

      # Search down through the firewall's data to find the AccessControlList (ACL) for the
      # "outside" interface which handles "in"-wardly directed traffic.  This is the list that
      # has the rules we're interested in.
      outside_interface_data = self["firewallInterfaces"].find { |firewall_interface_data| firewall_interface_data['name'] == 'outside' }
      if outside_interface_data
        incoming_ACL = outside_interface_data['firewallContextAccessControlLists'].find { |firewallACL_data| firewallACL_data['direction'] == 'in' }
        
        firewall_ACL = self.softlayer_client[:Network_Firewall_AccessControlList].object_with_id(incoming_ACL['id']).getObject
        rule_set = VLANFirewallRuleset.new(self.softlayer_client, firewall_ACL)
      end

      return rule_set
    end

    ##
    # collect a list of the firewalls on the account
    #
    def self.find_firewalls(client)
      softlayer_client = client || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      vlan_firewall_filter = SoftLayer::ObjectFilter.new() { |filter|
        filter.accept("networkVlans.networkVlanFirewall").when_it is_not_null
      }

      vlan_firewalls = client[:Account].object_mask(vlan_firewall_mask).object_filter(vlan_firewall_filter).getNetworkVlans
      vlan_firewalls.collect { |firewall_data| SoftLayer::VLANFirewall.new(client, firewall_data)}
    end

    private

    def self.vlan_firewall_mask
      return "mask[primaryRouter,dedicatedFirewallFlag,highAvailabilityFirewallFlag,"+
        "firewallInterfaces.firewallContextAccessControlLists," +
        "networkVlanFirewall[id, datacenter, primaryIpAddress, firewallType, fullyQualifiedDomainName]]"
    end
  end # class Firewall
end # module SoftLayer