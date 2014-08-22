#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  class Account < SoftLayer::ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader:
    # The company name of the primary contact
    sl_attr :companyName

    ##
    # :attr_reader:
    # The given name name of the primary contact
    sl_attr :firstName

    ##
    # :attr_reader:
    # The surname of the primary contact
    sl_attr :lastName

    ##
    # :attr_reader:
    # The first address line for the primary contact's address
    sl_attr :address1

    ##
    # :attr_reader:
    # The second address line (if any, may be nil) for the primary contact's address
    sl_attr :address2

    ##
    # :attr_reader:
    # The city stored as part of the primary contact's address
    sl_attr :city

    ##
    # :attr_reader:
    # The two character abbreviation for the state, province, or other similar national
    # division that is part of the address of the primary contact.  For addresses
    # outside of the US and Canada, where there may not be an equivalent to a state,
    # this may be 'NA' (for not applicable)
    sl_attr :state

    ##
    # :attr_reader:
    # The country stored as part of the primary contact's address
    sl_attr :country

    ##
    # :attr_reader:
    # The postal code (in the US, aka. zip code) of the primary contact's address
    sl_attr :postalCode

    ##
    # :attr_reader:
    # The office phone nubmer listed for the primary contact
    sl_attr :officePhone

    ##
    # The Bare Metal Servers (physical hardware) associated with the
    # account. Unless you force these to update, they will be refreshed every
    # five minutes.
    # :call-seq:
    #   bare_metal_servers(force_update=false)
    sl_dynamic_attr :bare_metal_servers do |bare_metal|
      bare_metal.should_update? do
        @last_bare_metal_update ||= Time.at(0)
        (Time.now - @last_bare_metal_update) > 5 * 60  # update every 5 minutes
      end

      bare_metal.to_update do
        @last_bare_metal_update = Time.now
        BareMetalServer.find_servers(:client => self.softlayer_client)
      end
    end

    ##
    # The virtual servers (aka. CCIs or Virtual_Guests) associated with the
    # account. Unless you force these to update, they will be refreshed every
    # five minutes.
    # :call-seq:
    #   virtual_servers(force_update=false)
    sl_dynamic_attr :virtual_servers do |virtual_servers|
      virtual_servers.should_update? do
        @last_virtual_server_update ||= Time.at(0)
        (Time.now - @last_virtual_server_update) > 5 * 60  # update every 5 minutes
      end

      virtual_servers.to_update do
        @last_virtual_server_update = Time.now
        VirtualServer.find_servers(:client => self.softlayer_client)
      end
    end

    sl_dynamic_attr :image_templates do |image_templates|
      image_templates.should_update? do
        @last_image_template_update ||= Time.at(0)
        (Time.now - @last_image_template_update) > 5 * 60  # update every 5 minutes
      end

      image_templates.to_update do
        @last_image_template_update ||= Time.now
        ImageTemplate.find_private_templates(:client => self.softlayer_client)
      end
    end

    sl_dynamic_attr :open_tickets do |open_tickets|
      open_tickets.should_update? do
        @last_open_tickets_update ||= Time.at(0)
        (Time.now - @last_open_tickets_update) > 5 * 60  # update every 5 minutes
      end

      open_tickets.to_update do
        @last_open_tickets_update ||= Time.now
        open_tickets_data = self.service.object_mask(SoftLayer::Ticket.default_object_mask).getOpenTickets
        open_tickets_data.collect { |ticket_data| SoftLayer::Ticket.new(self.softlayer_client, ticket_data) }
      end
    end

    def service
      softlayer_client[:Account].object_with_id(self.id)
    end

    ##
    # Searches the account's list of VLANs for the ones with the given
    # vlan number. This may return multiple results because a VLAN can
    # span different routers and you will get a separate segment for
    # each router.
    #
    # The IDs of the different segments can be helpful for ordering
    # firewalls.
    #
    def find_VLAN_with_number(vlan_number)
      filter = SoftLayer::ObjectFilter.new() { |filter|
        filter.accept('networkVlans.vlanNumber').when_it is vlan_number
      }

      vlan_data = self.service.object_mask("mask[id,vlanNumber,primaryRouter,networkSpace]").object_filter(filter).getNetworkVlans
      return vlan_data
    end
    
    ##
    # Using the login credentials in the client, retrieve
    # the account associated with those credentials.
    #
    def self.account_for_client(client = nil)
      softlayer_client = client || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      account_service = softlayer_client[:Account]
      network_hash = account_service.getObject()
      new(softlayer_client, network_hash)
    end

    ##
    # Get a list of the servers for the account. The list returned
    # includes both bare metal and virtual servers
    def servers
      return self.bare_metal_servers + self.virtual_servers
    end
  end
end