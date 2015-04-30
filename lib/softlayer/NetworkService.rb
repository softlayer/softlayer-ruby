#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # Each SoftLayer NetworkService instance provides connectivity
  # information for a specific Network Service Resource.
  #
  # This class roughly corresponds to the entity SoftLayer_Network_Service_Resource
  # in the API.
  #
  class NetworkService < ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader:
    # The name associated with this resource
    sl_attr :name

    ##
    # :attr_reader: private_ip
    # The backend IP address for this resource
    sl_attr :private_ip,   'backendIpAddress'

    ##
    # :attr_reader: public_ip
    # The frontend IP address for this resource
    sl_attr :public_ip,    'frontendIpAddress'

    ##
    # :attr_reader: ssh_username
    # The ssh username of for this resource
    sl_attr :ssh_username, 'sshUsername'

    ##
    # Retrieve the datacenter that this network service resource is available in
    # :call-seq:
    #   datacenter(force_update=false)
    sl_dynamic_attr :datacenter do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @datacenter == nil
      end

      resource.to_update do
        Datacenter::datacenter_named(self['datacenter']['name'], self.softlayer_client)
      end
    end

    ##
    # Returns the api properties used to connect to the network service resource
    #
    def api
      {
          'host'     => self['apiHost'],
          'password' => self['apiPassword'],
          'path'     => self['apiPath'],
          'port'     => self['apiPort'],
          'protocol' => self['apiProtocol'],
          'username' => self['apiUsername']
      }
    end

    ##
    # Returns the network service resource type name
    #
    def type
      self['type']['type']
    end

    protected

    def self.default_object_mask
      {
        "mask(SoftLayer_Network_Service_Resource)" => [
                                                       'apiHost',
                                                       'apiPassword',
                                                       'apiPath',
                                                       'apiPort',
                                                       'apiProtocol',
                                                       'apiUsername',
                                                       'backendIpAddress',
                                                       'datacenter',
                                                       'frontendIpAddress',
                                                       'id',
                                                       'name',
                                                       'networkDevice.id',
                                                       'sshUsername',
                                                       'type.type'
                                                      ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
