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
    # * <b>+:virtual_guest+</b> (Hash)   - Include network storage credentials from network storage matching these virtual_server properties
    #
    # You may use the following properties in the above :hardware and :virtual_server filters:
    # * <b>+:datacenter+</b>    (string) - Include network storage credentials from servers matching this datacenter
    # * <b>+:domain+</b>        (string) - Include network storage credentials from servers matching this domain
    # * <b>+:hostname+</b>      (string) - Include network storage credentials from servers matching this hostname
    #
    def self.find_network_storage_credentials(options_hash = {})
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
        :username      => "credentials.username",
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

      network_storage_data        = account_service.getNetworkStorage.collect{ |net_stor| NetworkStorage.new(softlayer_client, net_stor) unless net_stor.empty? }.compact
      network_storage_credentials = network_storage_data.map { |network_storage| network_storage.credentials }.flatten

      net_stor_credentials_by_id = network_storage_credentials.inject({}) do |net_stor_credentials_by_id, net_stor_cred|
        if options_hash[:username]
          net_stor_credentials_by_id[net_stor_cred['id']] ||= net_stor_cred if net_stor_cred.username == options_hash[:username]
        else
          net_stor_credentials_by_id[net_stor_cred['id']] ||= net_stor_cred
        end
        net_stor_credentials_by_id
      end
      net_stor_credentials_by_id.values
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
