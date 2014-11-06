#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # Each SoftLayer AccountPassword instance provides information about
  # a user's password associated with a SoftLayer Account instance.
  #
  # This class roughly corresponds to the entity SoftLayer_Account_Password
  # in the API.
  #
  class AccountPassword < ModelBase
    include ::SoftLayer::DynamicAttribute
    
    ##
    # :attr_reader:
    # A simple description of a username/password combination.
    sl_attr :notes

    ##
    # :attr_reader:
    # The password portion of a username/password combination.
    sl_attr :password

    ##
    # :attr_reader:
    # The username portion of a username/password combination.
    sl_attr :username

    ##
    # A description of the use for the account username/password combination.
    sl_dynamic_attr :description do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @description == nil
      end

      resource.to_update do
        type = self.service.getType
        type['description']
      end
    end

    ##
    # Updates the notes for the current account password.
    #
    def notes=(notes)
      self.service.editObject({ "notes" => notes.to_s })
      self.refresh_details()
    end

    ##
    # Updates the password for the current account password.
    #
    def password=(password)
      raise ArgumentError, "The new password cannot be nil"   unless password
      raise ArgumentError, "The new password cannot be empty" if password.empty?

      self.service.editObject({ "password" => password.to_s })
      self.refresh_details()
    end

    ##
    # Retrieve a list of network storage account passwords from all network storage devices.
    #
    # The options parameter should contain:
    #
    # <b>+:client+</b> - The client used to connect to the API
    #
    # If no client is given, then the routine will try to use Client.default_client
    # If no client can be found the routine will raise an error.
    #
    # You may filter the list returned by adding options:
    # * <b>+:hardware+</b>      (Hash)   - Include network storage account passwords from network storage matching these hardware properties
    # * <b>+:nas_type+</b>      (string) - Include network storage account passwords from devices of this storage type
    # * <b>+:username+</b>      (string) - Include network storage account passwords with this username only
    # * <b>+:virtual_guest+</b> (Hash)   - Include network storage account passwords from network storage matching these virtual_server properties
    #
    # You may use the following properties in the above :hardware and :virtual_server filters:
    # * <b>+:datacenter+</b>    (string) - Include network storage account passwords from servers matching this datacenter
    # * <b>+:domain+</b>        (string) - Include network storage account passwords from servers matching this domain
    # * <b>+:hostname+</b>      (string) - Include network storage account passwords from servers matching this hostname
    #
    def self.find_network_storage_account_passwords(options_hash = {})
      softlayer_client = options_hash[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      if(options_hash.has_key? :object_filter)
        object_filter = options_hash[:object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        object_filter = ObjectFilter.new()
      end

      if options_hash.has_key?(:hardware) && options_hash.has_key?(:virtual_guest)
        raise "Expected only one of :hardware or :virtual_guest options in #{__method__}"
      end

      if options_hash.has_key?(:hardware)
        raise "Expected an instance of Hash for option :hardware in #{__method__}" unless options_hash[:hardware].kind_of?(Hash)
      end

      if options_hash.has_key?(:virtual_guest)
        raise "Expected an instance of Hash for option :virtual_guest in #{__method__}" unless options_hash[:virtual_guest].kind_of?(Hash)
      end

      option_to_filter_path = {
        :hardware      => {
          :datacenter  => "hardware.datacenter.name",
          :domain      => "hardware.domain",
          :hostname    => "hardware.hostname"
        },
        :nas_type      => "nasType",
        :username      => "accountPassword.username",
        :virtual_guest => {
          :datacenter  => "virtualGuest.datacenter.name",
          :domain      => "virtualGuest.domain",
          :hostname    => "virtualGuest.hostname"
        }
      }

      object_filter.modify do |filter|
        filter.accept(option_to_filter_path[:nas_type]).when_it is(options_hash[:nas_type]) if options_hash[:nas_type]
        filter.accept(option_to_filter_path[:username]).when_it is(options_hash[:username]) if options_hash[:username]

        if options_hash.has_key?(:hardware)
          filter.accept(option_to_filter_path[:hardware][:datacenter]).when_it is(options_hash[:hardware][:datacenter]) if options_hash[:hardware].has_key?(:datacenter)
          filter.accept(option_to_filter_path[:hardware][:domain]).when_it     is(options_hash[:hardware][:domain])     if options_hash[:hardware].has_key?(:domain)
          filter.accept(option_to_filter_path[:hardware][:hostname]).when_it   is(options_hash[:hardware][:hostname])   if options_hash[:hardware].has_key?(:hostname)
        end

        if options_hash.has_key?(:virtual_guest)
          filter.accept(option_to_filter_path[:virtual_guest][:datacenter]).when_it is(options_hash[:virtual_guest][:datacenter]) if options_hash[:virtual_guest].has_key?(:datacenter)
          filter.accept(option_to_filter_path[:virtual_guest][:domain]).when_it     is(options_hash[:virtual_guest][:domain])     if options_hash[:virtual_guest].has_key?(:domain)
          filter.accept(option_to_filter_path[:virtual_guest][:hostname]).when_it   is(options_hash[:virtual_guest][:hostname])   if options_hash[:virtual_guest].has_key?(:hostname)
        end
      end
      
      account_service = softlayer_client[:Account]
      account_service = account_service.object_filter(object_filter) unless object_filter.empty?
      account_service = account_service.object_mask(NetworkStorage.default_object_mask)

      network_storage_data   = account_service.getNetworkStorage.collect{ |net_stor| NetworkStorage.new(softlayer_client, net_stor) unless net_stor.empty? }.compact
      net_stor_acct_pw_by_id = network_storage_data.inject({}) do |net_stor_acct_pw_by_id, net_stor|
        if options_hash[:username]
          net_stor_acct_pw_by_id[net_stor.account_password['id']] ||= net_stor.account_password if net_stor.account_password && net_stor.account_password.username == options_hash[:username]
        else
          net_stor_acct_pw_by_id[net_stor.account_password['id']] ||= net_stor.account_password if net_stor.account_password
        end
        net_stor_acct_pw_by_id
      end
      net_stor_acct_pw_by_id.values
    end

    ##
    # Retrieve a list of network storage webcc passwords from all network storage devices.
    #
    # The options parameter should contain:
    #
    # <b>+:client+</b> - The client used to connect to the API
    #
    # If no client is given, then the routine will try to use Client.default_client
    # If no client can be found the routine will raise an error.
    #
    # You may filter the list returned by adding options:
    # * <b>+:hardware+</b>      (Hash)   - Include network storage account passwords from network storage matching these hardware properties
    # * <b>+:nas_type+</b> (string) - Include network storage webcc passwords from devices of this storage type
    # * <b>+:username+</b> (string) - Include network storage webcc passwords with this username only
    # * <b>+:virtual_guest+</b> (Hash)   - Include network storage account passwords from network storage matching these virtual_server properties
    #
    # You may use the following properties in the above :hardware and :virtual_server filters:
    # * <b>+:datacenter+</b>    (string) - Include network storage account passwords from servers matching this datacenter
    # * <b>+:domain+</b>        (string) - Include network storage account passwords from servers matching this domain
    # * <b>+:hostname+</b>      (string) - Include network storage account passwords from servers matching this hostname
    #
    def self.find_network_storage_webcc_passwords(options_hash = {})
      softlayer_client = options_hash[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      if(options_hash.has_key? :object_filter)
        object_filter = options_hash[:object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        object_filter = ObjectFilter.new()
      end

      if options_hash.has_key?(:hardware) && options_hash.has_key?(:virtual_guest)
        raise "Expected only one of :hardware or :virtual_guest options in #{__method__}"
      end

      if options_hash.has_key?(:hardware)
        raise "Expected an instance of Hash for option :hardware in #{__method__}" unless options_hash[:hardware].kind_of?(Hash)
      end

      if options_hash.has_key?(:virtual_guest)
        raise "Expected an instance of Hash for option :virtual_guest in #{__method__}" unless options_hash[:virtual_guest].kind_of?(Hash)
      end

      option_to_filter_path = {
        :hardware      => {
          :datacenter  => "hardware.datacenter.name",
          :domain      => "hardware.domain",
          :hostname    => "hardware.hostname"
        },
        :nas_type      => "nasType",
        :username      => "webccAccount.username",
        :virtual_guest => {
          :datacenter  => "virtualGuest.datacenter.name",
          :domain      => "virtualGuest.domain",
          :hostname    => "virtualGuest.hostname"
        }
      }

      object_filter.modify do |filter|
        filter.accept(option_to_filter_path[:nas_type]).when_it is(options_hash[:nas_type]) if options_hash[:nas_type]
        filter.accept(option_to_filter_path[:username]).when_it is(options_hash[:username]) if options_hash[:username]

        if options_hash.has_key?(:hardware)
          filter.accept(option_to_filter_path[:hardware][:datacenter]).when_it is(options_hash[:hardware][:datacenter]) if options_hash[:hardware].has_key?(:datacenter)
          filter.accept(option_to_filter_path[:hardware][:domain]).when_it     is(options_hash[:hardware][:domain])     if options_hash[:hardware].has_key?(:domain)
          filter.accept(option_to_filter_path[:hardware][:hostname]).when_it   is(options_hash[:hardware][:hostname])   if options_hash[:hardware].has_key?(:hostname)
        end

        if options_hash.has_key?(:virtual_guest)
          filter.accept(option_to_filter_path[:virtual_guest][:datacenter]).when_it is(options_hash[:virtual_guest][:datacenter]) if options_hash[:virtual_guest].has_key?(:datacenter)
          filter.accept(option_to_filter_path[:virtual_guest][:domain]).when_it     is(options_hash[:virtual_guest][:domain])     if options_hash[:virtual_guest].has_key?(:domain)
          filter.accept(option_to_filter_path[:virtual_guest][:hostname]).when_it   is(options_hash[:virtual_guest][:hostname])   if options_hash[:virtual_guest].has_key?(:hostname)
        end
      end
      
      account_service = softlayer_client[:Account]
      account_service = account_service.object_filter(object_filter) unless object_filter.empty?
      account_service = account_service.object_mask(NetworkStorage.default_object_mask)
      account_service = account_service.object_mask(options_hash[:object_mask]) if options_hash.has_key?(:object_mask)

      network_storage_data    = account_service.getNetworkStorage.collect{ |net_stor| NetworkStorage.new(softlayer_client, net_stor) unless net_stor.empty? }.compact
      net_stor_webcc_pw_by_id = network_storage_data.inject({}) do |net_stor_webcc_pw_by_id, net_stor|
        if options_hash[:username]
          net_stor_webcc_pw_by_id[net_stor.webcc_account['id']] ||= net_stor.webcc_account if net_stor.webcc_account && net_stor.webcc_account.username == options_hash[:username]
        else
          net_stor_webcc_pw_by_id[net_stor.webcc_account['id']] ||= net_stor.webcc_account if net_stor.webcc_account
        end
        net_stor_webcc_pw_by_id
      end
      net_stor_webcc_pw_by_id.values
    end

    ##
    # Returns the service for interacting with this account password through the network API
    #
    def service
      softlayer_client[:Account_Password].object_with_id(self.id)
    end

    ##
    # Make an API request to SoftLayer and return the latest properties hash
    # for this object.
    #
    def softlayer_properties(object_mask = nil)
      my_service = self.service

      if(object_mask)
        my_service = my_service.object_mask(object_mask)
      else
        my_service = my_service.object_mask(self.class.default_object_mask)
      end

      my_service.getObject()
    end

    protected

    def self.default_object_mask
      {
        "mask(SoftLayer_Account_Password)" => [
                                               'id',
                                               'notes',
                                               'password',
                                               'username'
                                              ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
