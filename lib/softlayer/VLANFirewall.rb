#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  # The VLANFirewall class represents the firewall that protects
  # all the servers on a VLAN in the SoftLayer Environment.  It is
  # also known as a "Dedicated Firewall" in some documentation.
  #
  # Instances of this class are a bit odd because they actually represent
  # VLANs (the VLAN protected by the firewall) and not the physical hardware
  # implementing the firewall itself. (although the device is accessible as
  # the "networkVlanFirewall" property)
  #
  # As a result, instances of this class correspond to certain instances
  # in the SoftLayer_Network_Vlan service.
  #
	class VLANFirewall < SoftLayer::ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    #:attr_reader:
    #
    # The number of the VLAN protected by this firewall
    #
    sl_attr :VLAN_number, 'vlanNumber'

    ##
    # :attr_reader:
    #
    # The set of rules applied by this firewall to incoming traffic.
    # The object will retrieve the rules from the network API every
    # time you ask it for the rules.
    #
    # The code will sort the rules by their "orderValue" which is the
    # order that the firewall applies the rules, however please see
    # the important note in change_rules! concerning the "orderValue"
    # property of the rules.
    sl_dynamic_attr :rules do |firewall_rules|
      firewall_rules.should_update? do
        # firewall rules update every time you ask for them.
        return true
      end

      firewall_rules.to_update do
        acl_id = rules_ACL_id()
        rules_data = self.softlayer_client[:Network_Firewall_AccessControlList].object_with_id(acl_id).object_mask(self.class.default_rules_mask).getRules
        rules_data.sort { |lhs, rhs| lhs['orderValue'] <=> rhs['orderValue'] }
      end
    end

    ##
    # Change the set of rules for the firewall.
    # The rules_data parameter should be an array of hashes where
    # each hash gives the conditions of the rule. The keys of the
    # hashes should be entries from the array returned by
    # SoftLayer::ServerFirewall.default_rules_mask_keys
    #
    # *NOTE!* The rules themselves have an "orderValue" property.
    # It is this property, and *not* the order that the rules are
    # found in the rules_data array, which will determine in which
    # order the firewall applies it's rules to incomming traffic.
    #
    # *NOTE!* Changes to the rules are not applied immediately
    # on the server side. Instead, they are enqueued by the
    # firewall update service and updated periodically. A typical
    # update will take about one minute to apply, but times may vary
    # depending on the system load and other circumstances.
    def change_rules!(rules_data)
      change_object = {
        "firewallContextAccessControlListId" => self.id,
        "rules" => rules_data
      }

      self.softlayer_client[:Network_Firewall_Update_Request].createObject(change_object)
    end

    ##
    # Returns the name of the primary router the firewall is attached to.
    # This is often a "customer router" in one of the datacenters.
    def primaryRouter
      return self['primaryRouter']['hostname']
    end

    ##
    # The fully qualified domain name of the physical device the
    # firewall is implemented by.
    def fullyQualifiedDomainName
      if self.has_sl_property?('networkVlanFirewall')
        return self['networkVlanFirewall']['fullyQualifiedDomainName']
      else
        return @softlayer_hash
      end
    end

    ##
    # Returns true if this is a "high availability" firewall, that is a firewall
    # that exists as one member of a redundant pair.
    def high_availability?
      # note that highAvailabilityFirewallFlag is a boolean in the softlayer hash
      return self.has_sl_property?('highAvailabilityFirewallFlag') && self['highAvailabilityFirewallFlag']
    end

    ##
    # Collect a list of the firewalls on the account.
    #
    # This list is obtained by asking the account for all the VLANs
    # it has that also have a networkVlanFirewall component.
    def self.find_firewalls(client)
      softlayer_client = client || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      # only VLAN firewallas have a networkVlanFirewall component
      vlan_firewall_filter = SoftLayer::ObjectFilter.new() { |filter|
        filter.accept("networkVlans.networkVlanFirewall").when_it is_not_null
      }

      vlan_firewalls = client[:Account].object_mask(vlan_firewall_mask).object_filter(vlan_firewall_filter).getNetworkVlans
      vlan_firewalls.collect { |firewall_data| SoftLayer::VLANFirewall.new(client, firewall_data)}
    end


    #--
    # Methods for the SoftLayer model
    #++

    def service
      # Objects of this class are a bit odd because they actually represent VLANs (the VLAN protected by the firewall)
      # and not the physical hardware implementing the firewall itself.  (although the device is accessible as the
      # "networkVlanFirewall" property)
      self.softlayer_client[:Network_Vlan].object_with_id(self.id)
    end

    def softlayer_properties(object_mask = nil)
      service = self.service
      service = service.object_mask(object_mask) if object_mask
      service.object_mask(self.class.vlan_firewall_mask).getObject
    end

    #--
    #++
    private

    # Searches the set of access control lists for the firewall device in order to locate the one that
    # sits on the "outside" side of the network and handles 'in'coming traffic.
    def rules_ACL_id
      outside_interface_data = self['firewallInterfaces'].find { |interface_data| interface_data['name'] == 'outside' }
      incoming_ACL = outside_interface_data['firewallContextAccessControlLists'].find { |firewallACL_data| firewallACL_data['direction'] == 'in' } if outside_interface_data

      if incoming_ACL
        return incoming_ACL['id']
      else
        return nil
      end
    end

    def self.vlan_firewall_mask
      return "mask[primaryRouter,highAvailabilityFirewallFlag,"+
        "firewallInterfaces.firewallContextAccessControlLists," +
        "networkVlanFirewall[id, datacenter, primaryIpAddress, firewallType, fullyQualifiedDomainName]]"
    end

    def self.default_rules_mask
      return { "mask" => default_rules_mask_keys }.to_sl_object_mask
    end

    def self.default_rules_mask_keys
      ['orderValue','action','destinationIpAddress','destinationIpSubnetMask',"protocol","destinationPortRangeStart","destinationPortRangeEnd",'sourceIpAddress',"sourceIpSubnetMask","version"]
    end
  end # class Firewall
end # module SoftLayer