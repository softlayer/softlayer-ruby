#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # Each SoftLayer NetworkStorageCredential instance provides information
  # on a username/password credential combination used to access a specific
  # Network Storage.
  #
  # This class roughly corresponds to the entity SoftLayer_Network_Storage_Credential
  # in the API.
  #
  class NetworkStorageCredential < ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader:
    # This is the data that the record was created in the table.
    sl_attr :created,  'createDate'

    ##
    # :attr_reader:
    # This is the date that the record was last updated in the table.
    sl_attr :modified, 'modifyDate'

    ##
    # :attr_reader:
    # This is the password associated with the volume.
    sl_attr :password

    ##
    # :attr_reader:
    # This is the username associated with the volume.
    sl_attr :username
 
    ##
    # Returns a description of the Network Storage Credential type
    #
    def description
      self['type']['description']
    end

    ##
    # Returns the name of the Network Storage Credential type
    #
    def name
      self['type']['name']
    end

    ##
    # Retrieve a list of network storage credentials from all network storage devices.
    #
    # The options parameter should contain:
    #
    # <b>+:client+</b> - The client used to connect to the API
    #
    # If no client is given, then the routine will try to use Client.default_client
    # If no client can be found the routine will raise an error.
    #
    # You may filter the list returned by adding options:
    # * <b>+:datacenter+</b>                  (string) - Include network storage account passwords associated with servers matching this datacenter
    # * <b>+:domain+</b>                      (string) - Include network storage account passwords associated with servers matching this domain
    # * <b>+:hostname+</b>                    (string) - Include network storage account passwords associated with servers matching this hostname
    # * <b>+:network_storage_server_type+</b> (string) - Include network storage account passwords associated with services of this server type
    # * <b>+:network_storage_type+</b>        (string) - Include network storage account passwords from devices of this storage type
    # * <b>+:service+</b>                     (string) - Include network storage account passwords from devices with this service fqdn
    # * <b>+:tags+</b>                        (Array)  - Include network storage account passwords associated with servers matching these tags
    # * <b>+:username+</b>                    (string) - Include network storage account passwords with this username only
    #
    def self.find_network_storage_credentials(options_hash = {})
      softlayer_client = options_hash[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      if(options_hash.has_key? :network_storage_object_filter)
        network_storage_object_filter = options_hash[:network_storage_object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless network_storage_object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        network_storage_object_filter = ObjectFilter.new()
      end

      if(options_hash.has_key? :network_storage_credential_object_filter)
        network_storage_credential_object_filter = options_hash[:network_storage_credential_object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless network_storage_credential_object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        network_storage_credential_object_filter = ObjectFilter.new()
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
        :network_storage_credential => {
          :username                 => "credentials.username"
        }
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

      option_to_filter_path[:network_storage_credential].each do |option, filter_path|
        network_storage_credential_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option]) } if options_hash[option]
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

      network_storage_credentials = network_storage_data.collect do |network_storage|
        network_storage_service = softlayer_client[:Network_Storage].object_with_id(network_storage['id'])
        network_storage_service = network_storage_service.object_filter(network_storage_credential_object_filter) unless network_storage_credential_object_filter.empty?
        network_storage_service = network_storage_service.object_mask(NetworkStorageCredential.default_object_mask)
        network_storage_service = network_storage_service.object_mask(options_hash[:network_storage_credential_object_mask]) if options_hash[:network_storage_credential_object_mask]

        network_storage_credentials_data = network_storage_service.getCredentials
        network_storage_credentials_data.map { |credential| NetworkStorageCredential.new(softlayer_client, credential) unless credential.empty? }.compact
      end

      network_storage_credentials.flatten
    end

    protected

    def self.default_object_mask
      {
        "mask(SoftLayer_Network_Storage_Credential)" => [
                                                         'createDate',
                                                         'id',
                                                         'modifyDate',
                                                         'password',
                                                         'type.description',
                                                         'type.name',
                                                         'username'
                                                        ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
