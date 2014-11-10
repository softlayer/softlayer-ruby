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
    # * <b>+:hardware+</b>      (Hash)   - Include network storage credentials from network storage matching these hardware properties
    # * <b>+:nas_type+</b>      (string) - Include network storage credentials from devices of this storage type
    # * <b>+:username+</b>      (string) - Include network storage credentials with this username only
    # * <b>+:virtual_server+</b> (Hash)   - Include network storage credentials from network storage matching these virtual_server properties
    #
    # You may use the following properties in the above :hardware and :virtual_server filters:
    # * <b>+:datacenter+</b>    (string) - Include network storage credentials from servers matching this datacenter
    # * <b>+:domain+</b>        (string) - Include network storage credentials from servers matching this domain
    # * <b>+:hostname+</b>      (string) - Include network storage credentials from servers matching this hostname
    # * <b>+:tags+</b>          (Array)  - Include network storage credentials from servers matching these tags
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

      if options_hash.has_key?(:hardware) && options_hash.has_key?(:virtual_server)
        raise "Expected only one of :hardware or :virtual_server options in #{__method__}"
      end

      if options_hash.has_key?(:hardware)
        raise "Expected an instance of Hash for option :hardware in #{__method__}" unless options_hash[:hardware].kind_of?(Hash)
      end

      if options_hash.has_key?(:virtual_server)
        raise "Expected an instance of Hash for option :virtual_server in #{__method__}" unless options_hash[:virtual_server].kind_of?(Hash)
      end

      option_to_filter_path = {
        :hardware        => {
          :datacenter    => "networkStorage.hardware.datacenter.name",
          :domain        => "networkStorage.hardware.domain",
          :hostname      => "networkStorage.hardware.hostname"
        },
        :network_storage => {
          :nas_type      => "nasType"
        },
        :network_storage_credential => {
          :username      => "credentials.username"
        },
        :virtual_server  => {
          :datacenter    => "networkStorage.virtualGuest.datacenter.name",
          :domain        => "networkStorage.virtualGuest.domain",
          :hostname      => "networkStorage.virtualGuest.hostname"
        }
      }

      option_to_filter_path[:network_storage].each do |option, filter_path|
        network_storage_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option]) } if options_hash[option]
      end

      option_to_filter_path[:network_storage_credential].each do |option, filter_path|
        network_storage_credential_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option]) } if options_hash[option]
      end

      if options_hash[:hardware]
        option_to_filter_path[:hardware].each do |option, filter_path|
          network_storage_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[:hardware][option]) } if options_hash[:hardware][option]
        end

        if options_hash[:hardware].has_key?(:tags)
          network_storage_object_filter.set_criteria_for_key_path("networkStorage.hardware.tagReferences.tag.name",
                                                                  {
                                                                    'operation' => 'in',
                                                                    'options' => [{
                                                                                    'name' => 'data',
                                                                                    'value' => options_hash[:hardware][:tags].collect{ |tag_value| tag_value.to_s }
                                                                                  }]
                                                                  })
        end
      end

      if options_hash[:virtual_server]
        option_to_filter_path[:virtual_server].each do |option, filter_path|
          network_storage_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[:virtual_server][option]) } if options_hash[:virtual_server][option]
        end

        if options_hash[:virtual_server].has_key?(:tags)
          network_storage_object_filter.set_criteria_for_key_path("networkStorage.virtualGuest.tagReferences.tag.name",
                                                                  {
                                                                    'operation' => 'in',
                                                                    'options' => [{
                                                                                    'name' => 'data',
                                                                                    'value' => options_hash[:virtual_server][:tags].collect{ |tag_value| tag_value.to_s }
                                                                                  }]
                                                                  })
        end
      end

      account_service = softlayer_client[:Account]
      account_service = account_service.object_filter(network_storage_object_filter) unless network_storage_object_filter.empty?
      account_service = account_service.object_mask("mask[id]")

      network_storage_data        = account_service.getNetworkStorage
      network_storage_credentials = network_storage_data.collect do |network_storage|
        network_storage_service = softlayer_client[:Network_Storage].object_with_id(network_storage['id'])
        network_storage_service = network_storage_service.object_filter(network_storage_credential_object_filter) unless network_storage_credential_object_filter.empty?
        network_storage_service = network_storage_service.object_mask(NetworkStorageCredential.default_object_mask)
        network_storage_service = network_storage_service.object_mask(network_storage_credential_object_mask) if options_hash[:network_storage_credential_object_mask]

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
