#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # The ServerFirewall class represents a firewall in the
  # SoftLayer environment that exists in a 1 to 1 relationship
  # with a particular server (either Bare Metal or Virtual).
  #
  # This is also called a "Shared Firewall" in some documentation
  #
  # Instances of this class rougly correspond to instances of the
  # SoftLayer_Network_Component_Firewall service entity
  #
	class ServerFirewall < SoftLayer::ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader:
    # The state of the firewall, includes whether or not the rules are
    # editable and whether or not the firewall rules are applied or bypassed
    # Can at least be 'allow_edit', 'bypass' or 'no_edit'.
    # This list may not be exhaustive
    sl_attr :status

    ##
    # :attr_reader:
    # The firewall rules assigned to this firewall.  These rules will
    # be read from the network API every time you ask for the value
    # of this property.  To change the rules on the server use the
    # asymmetric method change_rules!
    sl_dynamic_attr :rules do |firewall_rules|
      firewall_rules.should_update? do
        # firewall rules update every time you ask for them.
        return true
      end

      firewall_rules.to_update do
        rules_data = self.service.object_mask(self.class.default_rules_mask).getRules()

        # At the time of this writing, the object mask sent to getRules is not
        # applied properly. This has been reported as a bug to the proper
        # development team. In the mean time, this extra step does filtering
        # that should have been done by the object mask.
        rules_keys = self.class.default_rules_mask_keys
        new_rules = rules_data.inject([]) do |new_rules, current_rule|
          new_rule = current_rule.delete_if { |key, value| !(rules_keys.include? key) }
          new_rules << new_rule
        end

        new_rules.sort { |lhs, rhs| lhs['orderValue'] <=> rhs['orderValue'] }
      end
    end

    ##
    # :attr_reader:
    # The server that this firewall is attached to. The result may be
    # either a bare metal or virtual server.
    #
    sl_dynamic_attr :protected_server do |protected_server|
      protected_server.should_update? do
        @protected_server == nil
      end

      protected_server.to_update do
        if has_sl_property?('networkComponent')
          @protected_server = SoftLayer::BareMetalServer.server_with_id(self['networkComponent']['downlinkComponent']['hardwareId'], :client => softlayer_client)
        end

        if has_sl_property?('guestNetworkComponent')
          @protected_server = SoftLayer::VirtualServer.server_with_id(self['guestNetworkComponent']['guest']['id'], :client => softlayer_client)
        end

        @protected_server
      end
    end

    ##
    # Calls super to initialize the object then initializes some
    # properties
    def initialize(client, network_hash)
      super(client, network_hash)
      @protected_server = nil
    end

    ##
    # Cancel the firewall
    #
    # This method cancels the firewall and releases its
    # resources.  The cancellation is processed immediately!
    # Call this method with careful deliberation!
    #
    # Notes is a string that describes the reason for the
    # cancellation. If empty or nil, a default string will
    # be added
    #
    def cancel!(notes = nil)
      user = self.softlayer_client[:Account].object_mask("mask[id,account]").getCurrentUser
      notes = "Cancelled by a call to #{__method__} in the softlayer_api gem" if notes == nil || notes == ""

      cancellation_request = {
        'accountId' => user['account']['id'],
        'userId'    => user['id'],
        'items' => [ {
          'billingItemId' => self['billingItem']['id'],
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
    # *NOTE!* The rules themselves have an "orderValue" property.
    # It is this property, and *not* the order that the rules are
    # found in the rules_data array, which will determine in which
    # order the firewall applies it's rules to incomming traffic.
    #
    # *NOTE!* Changes to the rules are not applied immediately
    # on the server side.  Instead, they are enqueued by the
    # firewall update service and updated periodically. A typical
    # update will take about one minute to apply, but times may vary
    # depending on the system load and other circumstances.
    def change_rules!(rules_data)
      change_object = {
        "networkComponentFirewallId" => self.id,
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
    # used with careful deliberation.
    #
    # Note that this routine queues a rule change and rule changes may take
    # time to process. The change will probably not take effect immediately
    #
    # The two symbols accepted as arguments by this routine are:
    # :apply_firewall_rules - The rules of the firewall are applied to traffic. This is the default operating mode of the firewall
    # :bypass_firewall_rules - The rules of the firewall are ignored. In this configuration the firewall provides no protection.
    #
    def change_rules_bypass!(bypass_symbol)
      change_object = {
        "networkComponentFirewallId" => self.id,
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
    # Locate and return all the server firewalls in the environment.
    #
    # These are a bit tricky to track down. The strategy we take here is
    # to look at the account and find all the VLANs that do NOT have their
    # "dedicatedFirewallFlag" set.
    #
    # With the list of VLANs in hand we check each to see if it has an
    # firewallNetworkComponents (corresponding to bare metal servers) or
    # firewallGuestNetworkComponents (corresponding to virtual servers) that
    # have a status of "allow_edit". Each such component is a firewall
    # interface on the VLAN with rules that the customer can edit.
    #
    # The collection of all those VLANs becomes the set of firewalls
    # for the account.
    #
    def self.find_firewalls(client = nil)
      softlayer_client = client || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      # Note that the dedicatedFirewallFlag is actually an integer and not a boolean
      # so we compare it against 0
      shared_vlans_filter = SoftLayer::ObjectFilter.new() { |filter|
        filter.accept("networkVlans.dedicatedFirewallFlag").when_it is(0)
      }

      bare_metal_firewalls_data = []
      virtual_firewalls_data = []

      shared_vlans = softlayer_client[:Account].object_mask(network_vlan_mask).object_filter(shared_vlans_filter).getNetworkVlans
      shared_vlans.each do |vlan_data|
        bare_metal_firewalls_data.concat vlan_data['firewallNetworkComponents'].select { |network_component| network_component['status'] != 'no_edit'}
        virtual_firewalls_data.concat vlan_data['firewallGuestNetworkComponents'].select { |network_component| network_component['status'] != 'no_edit'}
      end

      bare_metal_firewalls = bare_metal_firewalls_data.collect { |bare_metal_firewall_data|
        self.new(softlayer_client, bare_metal_firewall_data)
      }

      virtual_server_firewalls = virtual_firewalls_data.collect { |virtual_firewall_data|
        self.new(softlayer_client, virtual_firewall_data)
      }

      return bare_metal_firewalls + virtual_server_firewalls
    end

    #--
    # Methods for the SoftLayer model
    #++

    def service
      self.softlayer_client[:Network_Component_Firewall].object_with_id(self.id)
    end

    def softlayer_properties(object_mask = nil)
      service = self.service
      service = service.object_mask(object_mask) if object_mask

      if self.has_sl_property?('networkComponent')
        service.object_mask("mask[id,status,billingItem.id,networkComponent.downlinkComponent.hardwareId]").getObject
      else
        service.object_mask("mask[id,status,billingItem.id,guestNetworkComponent.guest.id]").getObject
      end
    end

    #--
    #++
    private

    def self.network_vlan_mask
      "mask[firewallNetworkComponents[id,status,billingItem.id,networkComponent.downlinkComponent.hardwareId],firewallGuestNetworkComponents[id,status,billingItem.id,guestNetworkComponent.guest.id]]"
    end

    def self.default_rules_mask
      return { "mask" => default_rules_mask_keys }.to_sl_object_mask
    end

    def self.default_rules_mask_keys
      ['orderValue','action','destinationIpAddress','destinationIpSubnetMask',"protocol","destinationPortRangeStart","destinationPortRangeEnd",'sourceIpAddress',"sourceIpSubnetMask","version"]
    end
  end # ServerFirewall class
end # SoftLayer module