#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # Each SoftLayer NetworkStorage instance provides information about
  # a storage product and access credentials.
  #
  # This class roughly corresponds to the entity SoftLayer_Network_Storage
  # in the API.
  #
  class NetworkStorage < ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader: capacity
    # A Storage account's capacity, measured in gigabytes.
    sl_attr :capacity,   'capacityGb'

    ##
    # :attr_reader: created_at
    # The date a network storage volume was created.
    sl_attr :created_at, 'createDate'

    ##
    # :attr_reader: created
    # The date a network storage volume was created.
    # DEPRECATION WARNING: This attribute is deprecated in favor of created_at
    # and will be removed in the next major release.
    sl_attr :created,    'createDate'

    ##
    # :attr_reader:
    # Public notes related to a Storage volume.
    sl_attr :notes

    ##
    # :attr_reader:
    # The password used to access a non-EVault Storage volume.
    # This password is used to register the EVault server agent with the
    # vault backup system.
    sl_attr :password

    ##
    # :attr_reader: type
    # A Storage account's type.
    sl_attr :type,       'nasType'

    ##
    # :attr_reader: upgradable
    # This flag indicates whether this storage type is upgradable or not.
    sl_attr :upgradable, 'upgradableFlag'

    ##
    # :attr_reader:
    # The username used to access a non-EVault Storage volume.
    # This username is used to register the EVault server agent with the
    # vault backup system.
    sl_attr :username

    ##
    # Retrieve other usernames and passwords associated with a Storage volume.
    # :call-seq:
    #   account_password(force_update=false)
    sl_dynamic_attr :account_password do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @account_password == nil
      end

      resource.to_update do
        account_password = self.service.object_mask(AccountPassword.default_object_mask).getAccountPassword
        AccountPassword.new(softlayer_client, account_password) unless account_password.empty?
      end
    end

    ##
    # A Storage volume's access credentials.
    # :call-seq:
    #   credentials(force_update=false)
    sl_dynamic_attr :credentials do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @credentials == nil
      end

      resource.to_update do
        self.service.object_mask(NetworkStorageCredential.default_object_mask).getCredentials.collect{|cred| NetworkStorageCredential.new(softlayer_client, cred) }
      end
    end

    ##
    # The network resource a Storage service is connected to.
    # :call-seq:
    #   service_resource(force_update=false)
    sl_dynamic_attr :service_resource do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @service_resource == nil
      end

      resource.to_update do
        NetworkService.new(softlayer_client, self.service.object_mask(NetworkService.default_object_mask).getServiceResource)
      end
    end

    ##
    # The account username and password for the EVault webCC interface.
    sl_dynamic_attr :webcc_account do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @webcc_account == nil
      end

      resource.to_update do
        webcc_account = self.service.object_mask(AccountPassword.default_object_mask).getWebccAccount
        AccountPassword.new(softlayer_client, webcc_account) unless webcc_account.empty?
      end
    end

    ##
    # Add a username/password credential to the network storage instance
    #
    def add_credential(credential_type)
      raise ArgumentError, "The new credential type cannot be nil"   unless credential_type
      raise ArgumentError, "The new credential type cannot be empty" if credential_type.empty?

      new_credential = self.service.object_mask(NetworkStorageCredential.default_object_mask).assignNewCredential(credential_type.to_s)
      
      @credentials = nil

      NetworkStorageCredential.new(softlayer_client, new_credential) unless new_credential.empty?
    end

    ##
    # Assign an existing network storage credential specified by the username to the network storage instance
    #
    def assign_credential(username)
      raise ArgumentError, "The username cannot be nil"   unless username
      raise ArgumentError, "The username cannot be empty" if username.empty?

      self.service.assignCredential(username.to_s)
      
      @credentials = nil
    end

    ##
    # Determines if one of the credentials pertains to the specified username.
    #
    def has_user_credential?(username)
      self.credentials.map { |credential| credential.username }.include?(username)
    end

    ##
    # Updates the notes for the network storage instance.
    #
    def notes=(notes)
      self.service.editObject({ "notes" => notes.to_s })
      self.refresh_details()
    end

    ##
    # Updates the password for the network storage instance.
    #
    def password=(password)
      raise ArgumentError, "The new password cannot be nil"   unless password
      raise ArgumentError, "The new password cannot be empty" if password.empty?

      self.service.editObject({ "password" => password.to_s })
      self.refresh_details()
    end

    ##
    # Remove an existing network storage credential specified by the username from the network storage instance
    #
    def remove_credential(username)
      raise ArgumentError, "The username cannot be nil"   unless username
      raise ArgumentError, "The username cannot be empty" if username.empty?

      self.service.removeCredential(username.to_s)
      
      @credentials = nil
    end

    ##
    # Retrieve a list of network storage services.
    #
    # The options parameter should contain:
    #
    # <b>+:client+</b> - The client used to connect to the API
    #
    # If no client is given, then the routine will try to use Client.default_client
    # If no client can be found the routine will raise an error.
    #
    # You may filter the list returned by adding options:
    # * <b>+:datacenter+</b>                  (string) - Include network storage associated with servers matching this datacenter
    # * <b>+:domain+</b>                      (string) - Include network storage associated with servers matching this domain
    # * <b>+:hostname+</b>                    (string) - Include network storage associated with servers matching this hostname
    # * <b>+:network_storage_server_type+</b> (string) - Include network storage associated with this server type
    # * <b>+:network_storage_type+</b>        (string) - Include network storage from devices of this storage type
    # * <b>+:service+</b>                     (string) - Include network storage from devices with this service fqdn
    # * <b>+:tags+</b>                        (Array)  - Include network storage associated with servers matching these tags
    #
    def self.find_network_storage(options_hash  = {})
      softlayer_client = options_hash[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      if(options_hash.has_key? :network_storage_object_filter)
        network_storage_object_filter = options_hash[:network_storage_object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless network_storage_object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        network_storage_object_filter = ObjectFilter.new()
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
        :datacenter                 => lambda { |storage_type, server_type| return [ filter_label[storage_type], '.', filter_label[server_type], '.datacenter.name' ].join                  },
        :domain                     => lambda { |storage_type, server_type| return [ filter_label[storage_type], '.', filter_label[server_type], '.domain' ].join                           },
        :hostname                   => lambda { |storage_type, server_type| return [ filter_label[storage_type], '.', filter_label[server_type], '.hostname' ].join                         },
        :service                    => lambda { |storage_type|              return [ filter_label[storage_type],                                 '.serviceResource.backendIpAddress' ].join },
        :tags                       => lambda { |storage_type, server_type| return [ filter_label[storage_type], '.', filter_label[server_type], '.tagReferences.tag.name' ].join           },
      }

      if options_hash[:network_storage_type]
        unless filter_label.select{|label,filter| filter.end_with?("Storage")}.keys.include?(options_hash[:network_storage_type])
          raise "Expected :evault, :hub, :iscsi, :lockbox, :nas or :network_storage for option :network_storage_type in #{__method__}"
        end
      end

      network_storage_type = options_hash[:network_storage_type] || :network_storage

      if options_hash[:service]
        network_storage_object_filter.modify do |filter|
          filter.accept(option_to_filter_path[:service].call(network_storage_type)).when_it is(options_hash[:service])
        end
      end
      
      if options_hash[:network_storage_server_type]
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

      account_service = softlayer_client[:Account]
      account_service = account_service.object_filter(network_storage_object_filter) unless network_storage_object_filter.empty?
      account_service = account_service.object_mask(NetworkStorage.default_object_mask)
      account_service = account_service.object_mask(options_hash[:network_storage_object_mask]) if options_hash[:network_storage_object_mask]

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

      network_storage_data.collect { |network_storage| NetworkStorage.new(softlayer_client, network_storage) unless network_storage.empty? }.compact
    end

    ##
    # Returns the service for interacting with this network storage through the network API
    #
    def service
      softlayer_client[:Network_Storage].object_with_id(self.id)
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

    ##
    # Updates the password for the network storage credential of the username specified.
    #
    def update_credential_password(username, password)
      raise ArgumentError, "The new password cannot be nil"   unless password
      raise ArgumentError, "The new username cannot be nil"   unless username
      raise ArgumentError, "The new password cannot be empty" if password.empty?
      raise ArgumentError, "The new username cannot be empty" if username.empty?

      self.service.editCredential(username.to_s, password.to_s)

      @credentials = nil
    end

    protected

    def self.default_object_mask
      {
        "mask(SoftLayer_Network_Storage)" => [
                                              'capacityGb',
                                              'createDate',
                                              'id',
                                              'nasType',
                                              'notes',
                                              'password',
                                              'upgradableFlag',
                                              'username'
                                             ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
