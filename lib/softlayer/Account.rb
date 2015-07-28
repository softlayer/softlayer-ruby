#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  class Account < SoftLayer::ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader: company_name
    # The company name of the primary contact
    sl_attr :company_name, 'companyName'

    ##
    # :attr_reader:
    # The company name of the primary contact
    #
    # DEPRECATION WARNING: This attribute is deprecated in favor of company_name
    # and will be removed in the next major release.
    sl_attr :companyName

    ##
    # :attr_reader: first_name
    # The given name name of the primary contact
    sl_attr :first_name, 'firstName'

    ##
    # :attr_reader:
    # The given name name of the primary contact
    #
    # DEPRECATION WARNING: This attribute is deprecated in favor of first_name
    # and will be removed in the next major release.
    sl_attr :firstName

    ##
    # :attr_reader: last_name
    # The surname of the primary contact
    sl_attr :last_name, 'lastName'

    ##
    # :attr_reader:
    # The surname of the primary contact
    #
    # DEPRECATION WARNING: This attribute is deprecated in favor of last_name
    # and will be removed in the next major release.
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
    # :attr_reader: postal_code
    # The postal code (in the US, aka. zip code) of the primary contact's address
    sl_attr :postal_code, 'postalCode'

    ##
    # :attr_reader:
    # The postal code (in the US, aka. zip code) of the primary contact's address
    #
    # DEPRECATION WARNING: This attribute is deprecated in favor of postal_code
    # and will be removed in the next major release.
    sl_attr :postalCode

    ##
    # :attr_reader: office_phone
    # The office phone number listed for the primary contact
    sl_attr :office_phone, 'officePhone'

    ##
    # :attr_reader:
    # The office phone number listed for the primary contact
    #
    # DEPRECATION WARNING: This attribute is deprecated in favor of office_phone
    # and will be removed in the next major release.
    sl_attr :officePhone

    ##
    # Retrieve the Bare Metal Servers (physical hardware) associated with the
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
    # Retrieve an account's master EVault user. This is only used when an account
    # has an EVault service.
    # :call-seq:
    #   evault_master_users(force_update=false)
    sl_dynamic_attr :evault_master_users do |evault_users|
      evault_users.should_update? do
        @evault_master_users == nil
      end

      evault_users.to_update do
        evault_user_passwords = self.service.object_mask(AccountPassword.default_object_mask).getEvaultMasterUsers
        evault_user_passwords.collect { |evault_user_password| AccountPassword.new(softlayer_client, evault_user_password) unless evault_user_password.empty? }.compact
      end
    end

    ##
    # Retrieve an account's image templates. Unless you force 
    # these to update, they will be refreshed every five minutes
    # :call-seq:
    #   image_templates(force_update=false)
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

    ##
    # Retrieve an account's network message delivery accounts.
    # :call-seq:
    #   network_message_delivery_accounts(force_update=false)
    sl_dynamic_attr :network_message_delivery_accounts do |net_msg_deliv_accts|
      net_msg_deliv_accts.should_update? do
        @network_message_delivery_accounts == nil
      end

      net_msg_deliv_accts.to_update do
        network_message_delivery_accounts = self.service.object_mask(NetworkMessageDelivery.default_object_mask).getNetworkMessageDeliveryAccounts
        network_message_delivery_accounts.collect { |net_msg_deliv_acct| NetworkMessageDelivery.new(softlayer_client, net_msg_deliv_acct) unless net_msg_deliv_acct.empty? }.compact
      end
    end

    ##
    # Retrieve an account's network storage groups.
    # :call-seq:
    #   network_storage_groups(force_update=false)
    sl_dynamic_attr :network_storage_groups do |net_stor_groups|
      net_stor_groups.should_update? do
        @network_storage_groups == nil
      end

      net_stor_groups.to_update do
        network_storage_groups = self.service.object_mask(NetworkStorageGroup.default_object_mask).getNetworkStorageGroups
        network_storage_groups.collect { |net_stor_group| NetworkStorageGroup.new(softlayer_client, net_stor_group) unless net_stor_group.empty? }.compact
      end
    end

    ##
    # Retrieve an account's open tickets. Unless you force these 
    # to update, they will be refreshed every five minutes
    # :call-seq:
    #   open_tickets(force_update=false)
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

    ##
    # Retrieve an account's portal users.
    # :call-seq:
    #   users(force_update=false)
    sl_dynamic_attr :users do |users|
      users.should_update? do
        @users == nil
      end

      users.to_update do
        account_users = self.service.object_mask(UserCustomer.default_object_mask).getUsers
        account_users.collect { |account_user| UserCustomer.new(softlayer_client, account_user) unless account_user.empty? }.compact
      end
    end

    ##
    # Retrieve an account's virtual disk images. Unless you force 
    # these to update, they will be refreshed every five minutes
    # :call-seq:
    #   virtual_disk_images(force_update=false)
    sl_dynamic_attr :virtual_disk_images do |virtual_disk_images|
      virtual_disk_images.should_update? do
        @last_virtual_disk_images_update ||= Time.at(0)
        (Time.now - @last_virtual_disk_images_update) > 5 * 60  # update every 5 minutes
      end

      virtual_disk_images.to_update do
        @last_virtual_disk_images_update ||= Time.now
        virtual_disk_images_data = self.service.object_mask(SoftLayer::VirtualDiskImage.default_object_mask).getVirtualDiskImages
        virtual_disk_images_data.collect { |virtual_disk_image| SoftLayer::VirtualDiskImage.new(softlayer_client, virtual_disk_image) }
      end
    end

    ##
    # Retrieve the virtual servers (aka. CCIs or Virtual_Guests) associated with the
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
    def find_vlan_with_number(vlan_number)
      filter = SoftLayer::ObjectFilter.new() { |filter|
        filter.accept('networkVlans.vlanNumber').when_it is vlan_number
      }

      vlan_data = self.service.object_mask("mask[id,vlanNumber,primaryRouter,networkSpace]").object_filter(filter).getNetworkVlans
      return vlan_data
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
    # DEPRECATION WARNING: This method is deprecated in favor of find_vlan_with_number
    # and will be removed in the next major release.
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
      Account.new(softlayer_client, network_hash)
    end

    ##
    # Get a list of the servers for the account. The list returned
    # includes both bare metal and virtual servers
    def servers
      return self.bare_metal_servers + self.virtual_servers
    end
  end
end
