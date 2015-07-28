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
  # Instances of this class are a bit odd because they actually represent a
  # VLAN (the VLAN protected by the firewall to be specific), and not the 
  # physical hardware implementing the firewall itself. (although the device 
  # is accessible as the "networkVlanFirewall" property)
  #
  # As a result, instances of this class correspond to certain instances
  # in the SoftLayer_Network_Vlan service.
  #
  class VLANFirewall < SoftLayer::ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader: vlan_number
    #
    # The number of the VLAN protected by this firewall.
    sl_attr :vlan_number, 'vlanNumber'

    ##
    # :attr_reader: VLAN_number
    #
    # The number of the VLAN protected by this firewall.
    #
    # DEPRECATION WARNING: This attribute is deprecated in favor of vlan_number
    # and will be removed in the next major release.
    sl_attr :VLAN_number, 'vlanNumber'

    ##
    # Retrieve the set of rules applied by this firewall to incoming traffic.
    # The object will retrieve the rules from the network API every
    # time you ask it for the rules.
    #
    # The code will sort the rules by their "orderValue" which is the
    # order that the firewall applies the rules, however please see
    # the important note in change_rules! concerning the "orderValue"
    # property of the rules.
    # :call-seq:
    #   rules(force_update=false)
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
    # Returns the name of the primary router the firewall is attached to.
    # This is often a "customer router" in one of the datacenters.
    def primary_router
      return self['primaryRouter']['hostname']
    end

    ##
    # Returns the name of the primary router the firewall is attached to.
    # This is often a "customer router" in one of the datacenters.
    #
    # DEPRECATION WARNING: This method is deprecated in favor of primary_router
    # and will be removed in the next major release.
    def primaryRouter
      return self['primaryRouter']['hostname']
    end

    ##
    # The fully qualified domain name of the physical device the
    # firewall is implemented by.
    def fqdn
      if self.has_sl_property?('networkVlanFirewall')
        return self['networkVlanFirewall']['fullyQualifiedDomainName']
      else
        return @softlayer_hash
      end
    end

    ##
    # The fully qualified domain name of the physical device the
    # firewall is implemented by.
    #
    # DEPRECATION WARNING: This method is deprecated in favor of fqdn
    # and will be removed in the next major release.
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
    # Cancel the firewall
    #
    # This method cancels the firewall and releases its
    # resources. The cancellation is processed immediately!
    # Call this method with careful deliberation!
    #
    # Notes is a string that describes the reason for the
    # cancellation. If empty or nil, a default string will
    # be added.
    #
    def cancel!(notes = nil)
      user = self.softlayer_client[:Account].object_mask("mask[id,account.id]").getCurrentUser
      notes = "Cancelled by a call to #{__method__} in the softlayer_api gem" if notes == nil || notes == ""

      cancellation_request = {
        'accountId' => user['account']['id'],
        'userId'    => user['id'],
        'items' => [ {
          'billingItemId' => self['networkVlanFirewall']['billingItem']['id'],
          'immediateCancellationFlag' => true
          } ],
        'notes' => notes
      }

      self.softlayer_client[:Billing_Item_Cancellation_Request].createObject(cancellation_request)
    end

    ##
    # Change the set of rules for the firewall.
    # The rules_data parameter should be an array of hashes where
    # each hash gives the conditions of the rule. The keys of the
    # hashes should be entries from the array returned by
    # SoftLayer::ServerFirewall.default_rules_mask_keys
    #
    # *NOTE!* When changing the rules on the firewall, you must
    # pass in a complete set of rules each time. The rules you
    # submit will replace the entire ruleset on the destination
    # firewall.
    #
    # *NOTE!* The rules themselves have an "orderValue" property.
    # It is this property, and *not* the order that the rules are
    # found in the rules_data array, which will determine in which
    # order the firewall applies its rules to incoming traffic.
    #
    # *NOTE!* Changes to the rules are not applied immediately
    # on the server side. Instead, they are enqueued by the
    # firewall update service and updated periodically. A typical
    # update will take about one minute to apply, but times may vary
    # depending on the system load and other circumstances.
    def change_rules!(rules_data)
      change_object = {
        "firewallContextAccessControlListId" => rules_ACL_id(),
        "rules" => rules_data
      }

      self.softlayer_client[:Network_Firewall_Update_Request].createObject(change_object)
    end

    ##
    # This method asks the firewall to ignore its rule set and pass all traffic
    # through the firewall. Compare the behavior of this routine with
    # change_routing_bypass!
    #
    # It is important to note that changing the bypass to :bypass_firewall_rules
    # removes ALL the protection offered by the firewall. This routine should be
    # used with extreme discretion.
    #
    # Note that this routine queues a rule change and rule changes may take
    # time to process. The change will probably not take effect immediately.
    #
    # The two symbols accepted as arguments by this routine are:
    # :apply_firewall_rules - The rules of the firewall are applied to traffic. This is the default operating mode of the firewall
    # :bypass_firewall_rules - The rules of the firewall are ignored. In this configuration the firewall provides no protection.
    #
    def change_rules_bypass!(bypass_symbol)
      change_object = {
        "firewallContextAccessControlListId" => rules_ACL_id(),
        "rules" => self.rules
      }

      case bypass_symbol
      when :apply_firewall_rules
        change_object['bypassFlag'] = false
        self.softlayer_client[:Network_Firewall_Update_Request].createObject(change_object)
      when :bypass_firewall_rules
        change_object['bypassFlag'] = true
        self.softlayer_client[:Network_Firewall_Update_Request].createObject(change_object)
      else
        raise ArgumentError, "An invalid parameter was sent to #{__method__}. It accepts :apply_firewall_rules and :bypass_firewall_rules"
      end
    end

    ##
    # This method allows you to route traffic around the firewall
    # and directly to the servers it protects. Compare the behavior of this routine with
    # change_rules_bypass!
    #
    # It is important to note that changing the routing to :route_around_firewall
    # removes ALL the protection offered by the firewall. This routine should be
    # used with extreme discretion.
    #
    # Note that this routine constructs a transaction. The Routing change
    # may not happen immediately.
    #
    # The two symbols accepted as arguments by the routine are:
    # :route_through_firewall - Network traffic is sent through the firewall to the servers in the VLAN segment it protects.  This is the usual operating mode of the firewall.
    # :route_around_firewall - Network traffic will be sent directly to the servers in the VLAN segment protected by this firewall.  This means that the firewall will *NOT* be protecting those servers.
    #
    def change_routing_bypass!(routing_symbol)
      vlan_firewall_id = self['networkVlanFirewall']['id']

      raise "Could not identify the device for a VLAN firewall" if !vlan_firewall_id

      case routing_symbol
      when :route_through_firewall
        self.softlayer_client[:Network_Vlan_Firewall].object_with_id(vlan_firewall_id).updateRouteBypass(false)
      when :route_around_firewall
        self.softlayer_client[:Network_Vlan_Firewall].object_with_id(vlan_firewall_id).updateRouteBypass(true)
      else
        raise ArgumentError, "An invalid parameter was sent to #{__method__}. It accepts :route_through_firewall and :route_around_firewall"
      end
    end

    ##
    # Collect a list of the firewalls on the account.
    #
    # This list is obtained by asking the account for all the VLANs
    # it has that also have a networkVlanFirewall component.
    def self.find_firewalls(client = nil)
      softlayer_client = client || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      # only VLAN firewalls have a networkVlanFirewall component
      vlan_firewall_filter = SoftLayer::ObjectFilter.new() { |filter|
        filter.accept("networkVlans.networkVlanFirewall").when_it is_not_null
      }

      vlan_firewalls = softlayer_client[:Account].object_mask(vlan_firewall_mask).object_filter(vlan_firewall_filter).getNetworkVlans
      vlan_firewalls.collect { |firewall_data| SoftLayer::VLANFirewall.new(softlayer_client, firewall_data)}
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
      return "mask[primaryRouter,highAvailabilityFirewallFlag," +
        "firewallInterfaces.firewallContextAccessControlLists," +
        "networkVlanFirewall[id,datacenter,primaryIpAddress,firewallType,fullyQualifiedDomainName,billingItem.id]]"
    end

    def self.default_rules_mask
      return { "mask" => default_rules_mask_keys }.to_sl_object_mask
    end

    def self.default_rules_mask_keys
      ['orderValue',
       'action',
       'destinationIpAddress',
       'destinationIpSubnetMask',
       'protocol',
       'destinationPortRangeStart',
       'destinationPortRangeEnd',
       'sourceIpAddress',
       'sourceIpSubnetMask',
       'version']
    end
  end # class Firewall
end # module SoftLayer
