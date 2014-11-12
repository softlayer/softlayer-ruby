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
    # * <b>+:datacenter+</b>                  (string) - Include network storage account passwords from servers matching this datacenter
    # * <b>+:domain+</b>                      (string) - Include network storage account passwords from servers matching this domain
    # * <b>+:hostname+</b>                    (string) - Include network storage account passwords from servers matching this hostname
    # * <b>+:network_storage_server_type+</b> (string) - Include network storage account passwords attached to this server type
    # * <b>+:network_storage_type+</b>        (string) - Include network storage account passwords from devices of this storage type
    # * <b>+:tags+</b>                        (Array)  - Include network storage account passwords from servers matching these tags
    # * <b>+:username+</b>                    (string) - Include network storage account passwords with this username only
    #
    def self.find_network_storage_account_passwords(options_hash = {})
      softlayer_client = options_hash[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      if(options_hash.has_key? :network_storage_object_filter)
        network_storage_object_filter = options_hash[:network_storage_object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless network_storage_object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        network_storage_object_filter = ObjectFilter.new()
      end

      if(options_hash.has_key? :account_password_object_filter)
        account_password_object_filter = options_hash[:account_password_object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless account_password_object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        account_password_object_filter = ObjectFilter.new()
      end

      if options_hash.has_key?(:network_storage_server_type) && ! [ :hardware, :virtual_server ].include?(options_hash[:network_storage_server_type])
        raise "Expected one of :hardware or :virtual_server for :network_storage_server_type option in #{__method__}"
      end

      filter_label = {
        :evault          => "evaultNetworkStorage",
        :hardware        => "hardware",
        :hub             => "hubNetworkStorage",
        :iscsi           => "iscsiNetworkStorage",
        :lockbox         => "lockboxNetworkStorage",
        :nas             => "nasNetworkStorage",
        :network_storage => "networkStorage",
        :virtual_server  => "virtualGuest"
      }

      option_to_filter_path = {
        :account_password => {
          :username       => "accountPassword.username"
        },
        :datacenter       => lambda { |storage_type, server_type| return [ filter_label[storage_type], '.', filter_label[server_type], '.datacenter.name' ].join        },
        :domain           => lambda { |storage_type, server_type| return [ filter_label[storage_type], '.', filter_label[server_type], '.domain' ].join                 },
        :hostname         => lambda { |storage_type, server_type| return [ filter_label[storage_type], '.', filter_label[server_type], '.hostname' ].join               },
        :tags             => lambda { |storage_type, server_type| return [ filter_label[storage_type], '.', filter_label[server_type], '.tagReferences.tag.name' ].join }
      }

      if options_hash[:network_storage_type]
        unless filter_label.select{|label,filter| filter.end_with?("Storage")}.keys.include?(options_hash[:network_storage_type])
          raise "Expected :evault, :hub, :iscsi, :lockbox, :nas or :network_storage for option :network_storage_type in #{__method__}"
        end
      end

      if options_hash[:network_storage_server_type]
        network_storage_type = options_hash[:network_storage_type] || :network_storage

        [ :datacenter, :domain, :hostname ].each do |option|
          if options_hash[option]
            network_storage_object_filter.modify do |filter|
              filter.accept(option_to_filter_path[option].call(network_storage_type, options_hash[:network_storage_server_type])).when_it is(options_hash[option])
            end
          end
        end

        if options_hash[:tags]
          network_storage_object_filter.set_criteria_for_key_path(option_to_filter_path[:tags].call(network_storage_type, options_hash[:network_storage_server_type]),
                                                                  {
                                                                    'operation' => 'in',
                                                                    'options' => [{
                                                                                    'name' => 'data',
                                                                                    'value' => options_hash[:tags].collect{ |tag_value| tag_value.to_s }
                                                                                  }]
                                                                  })
        end
      end

      option_to_filter_path[:account_password].each do |option, filter_path|
        account_password_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option]) } if options_hash[option]
      end

      account_service = softlayer_client[:Account]
      account_service = account_service.object_filter(network_storage_object_filter) unless network_storage_object_filter.empty?
      account_service = account_service.object_mask("mask[id]")

      case options_hash[:network_storage_type]
      when :evault
        network_storage_data = account_service.getEvaultNetworkStorage
      when :hub
        network_storage_data = account_service.getHubNetworkStorage
      when :iscsi
        network_storage_data = account_service.getIscsiNetworkStorage
      when :lockbox
        network_storage_data = account_service.getLockboxNetworkStorage
      when :nas
        network_storage_data = account_service.getNasNetworkStorage
      when :network_storage, nil
        network_storage_data = account_service.getNetworkStorage
      end

      account_passwords = network_storage_data.collect do |network_storage|
        network_storage_service = softlayer_client[:Network_Storage].object_with_id(network_storage['id'])
        network_storage_service = network_storage_service.object_filter(account_password_object_filter) unless account_password_object_filter.empty?
        network_storage_service = network_storage_service.object_mask(AccountPassword.default_object_mask)
        network_storage_service = network_storage_service.object_mask(options_hash[:account_password_object_mask]) if options_hash[:account_password_object_mask]

        account_password_data = network_storage_service.getAccountPassword
        AccountPassword.new(softlayer_client, account_password_data) unless account_password_data.empty?
      end

      account_passwords.compact
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
    # * <b>+:datacenter+</b>                  (string) - Include network storage webcc passwords from servers matching this datacenter
    # * <b>+:domain+</b>                      (string) - Include network storage webcc passwords from servers matching this domain
    # * <b>+:hostname+</b>                    (string) - Include network storage webcc passwords from servers matching this hostname
    # * <b>+:network_storage_server_type+</b> (string) - Include network storage webcc passwords attached to this server type
    # * <b>+:network_storage_type+</b>        (string) - Include network storage webcc passwords from devices of this storage type
    # * <b>+:tags+</b>                        (Array)  - Include network storage webcc passwords from servers matching these tags
    # * <b>+:username+</b>                    (string) - Include network storage webcc passwords with this username only
    #
    def self.find_network_storage_webcc_passwords(options_hash = {})
      softlayer_client = options_hash[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      if(options_hash.has_key? :network_storage_object_filter)
        network_storage_object_filter = options_hash[:network_storage_object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless network_storage_object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        network_storage_object_filter = ObjectFilter.new()
      end

      if(options_hash.has_key? :webcc_password_object_filter)
        webcc_password_object_filter = options_hash[:webcc_password_object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless webcc_password_object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        webcc_password_object_filter = ObjectFilter.new()
      end

      if options_hash.has_key?(:network_storage_server_type) && ! [ :hardware, :virtual_server ].include?(options_hash[:network_storage_server_type])
        raise "Expected one of :hardware or :virtual_server for :network_storage_server_type option in #{__method__}"
      end

      filter_label = {
        :evault          => "evaultNetworkStorage",
        :hardware        => "hardware",
        :hub             => "hubNetworkStorage",
        :iscsi           => "iscsiNetworkStorage",
        :lockbox         => "lockboxNetworkStorage",
        :nas             => "nasNetworkStorage",
        :network_storage => "networkStorage",
        :virtual_server  => "virtualGuest"
      }

      option_to_filter_path = {
        :datacenter       => lambda { |storage_type, server_type| return [ filter_label[storage_type], '.', filter_label[server_type], '.datacenter.name' ].join        },
        :domain           => lambda { |storage_type, server_type| return [ filter_label[storage_type], '.', filter_label[server_type], '.domain' ].join                 },
        :hostname         => lambda { |storage_type, server_type| return [ filter_label[storage_type], '.', filter_label[server_type], '.hostname' ].join               },
        :tags             => lambda { |storage_type, server_type| return [ filter_label[storage_type], '.', filter_label[server_type], '.tagReferences.tag.name' ].join },
        :webcc_password => {
          :username       => "webccAccount.username"
        }
      }

      if options_hash[:network_storage_type]
        unless filter_label.select{|label,filter| filter.end_with?("Storage")}.keys.include?(options_hash[:network_storage_type])
          raise "Expected :evault, :hub, :iscsi, :lockbox, :nas or :network_storage for option :network_storage_type in #{__method__}"
        end
      end

      if options_hash[:network_storage_server_type]
        network_storage_type = options_hash[:network_storage_type] || :network_storage

        [ :datacenter, :domain, :hostname ].each do |option|
          if options_hash[option]
            network_storage_object_filter.modify do |filter|
              filter.accept(option_to_filter_path[option].call(network_storage_type, options_hash[:network_storage_server_type])).when_it is(options_hash[option])
            end
          end
        end

        if options_hash[:tags]
          network_storage_object_filter.set_criteria_for_key_path(option_to_filter_path[:tags].call(network_storage_type, options_hash[:network_storage_server_type]),
                                                                  {
                                                                    'operation' => 'in',
                                                                    'options' => [{
                                                                                    'name' => 'data',
                                                                                    'value' => options_hash[:tags].collect{ |tag_value| tag_value.to_s }
                                                                                  }]
                                                                  })
        end
      end

      option_to_filter_path[:webcc_password].each do |option, filter_path|
        webcc_password_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option]) } if options_hash[option]
      end

      account_service = softlayer_client[:Account]
      account_service = account_service.object_filter(network_storage_object_filter) unless network_storage_object_filter.empty?
      account_service = account_service.object_mask("mask[id]")

      case options_hash[:network_storage_type]
      when :evault
        network_storage_data = account_service.getEvaultNetworkStorage
      when :hub
        network_storage_data = account_service.getHubNetworkStorage
      when :iscsi
        network_storage_data = account_service.getIscsiNetworkStorage
      when :lockbox
        network_storage_data = account_service.getLockboxNetworkStorage
      when :nas
        network_storage_data = account_service.getNasNetworkStorage
      when :network_storage, nil
        network_storage_data = account_service.getNetworkStorage
      end

      webcc_passwords = network_storage_data.collect do |network_storage|
        network_storage_service = softlayer_client[:Network_Storage].object_with_id(network_storage['id'])
        network_storage_service = network_storage_service.object_filter(webcc_password_object_filter) unless webcc_password_object_filter.empty?
        network_storage_service = network_storage_service.object_mask(AccountPassword.default_object_mask)
        network_storage_service = network_storage_service.object_mask(options_hash[:webcc_password_object_mask]) if options_hash[:webcc_password_object_mask]

        webcc_password_data = network_storage_service.getWebccAccount
        AccountPassword.new(softlayer_client, webcc_password_data) unless webcc_password_data.empty?
      end

      webcc_passwords.compact
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
