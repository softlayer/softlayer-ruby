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
    # :attr_reader:
    # The backend IP address for this resource
    sl_attr :private_ip,   'backendIpAddress'

    ##
    # :attr_reader:
    # The frontend IP address for this resource
    sl_attr :public_ip,    'frontendIpAddress'

    ##
    # :attr_reader:
    # The ssh username of for this resource
    sl_attr :ssh_username, 'sshUsername'

    ##
    # Returns the datacenter that this network service resource is available in
    sl_dynamic_attr :datacenter do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @datacenter == nil
      end

      resource.to_update do
        Datacenter::datacenter_named(self['datacenter']['name'], self.softlayer_client)
      end
    end

    #TODO: dependent_resources and related resources needs an object filter to start from
    # Account -> getNetworkStorage -> getServiceResource and find only the resource with
    # the id and create an instance since this data type doesnt have an associated service.
    # Are dependent/related resources restricted to the same network hardware device? If so
    # thats easier to implement. The mask for these also isnt working.

    ##
    # Returns the list of network service resources that are dependent on the current
    # network service resource
    #sl_dynamic_attr :dependent_resources do |resource|
      #resource.should_update? do
        #only retrieved once per instance
        # @dependent_resources == nil
      #end

      #resource.to_update do
        #dependent_resources = self.service.object_mask("mask[dependentResources.id]").getObject
        #dependent_resources.collect do |dep_res|
          #dep_res_service = self.service.object_with_id(dep_res['id'])
          #dep_res_service = dep_res_service.object_mask(self.default_object_mask)
          #NetworkService.new(self.softlayer_client, dep_res_service.getObject)
        #end
      #end
    #end

    ##
    # Returns the list of network service resources that are related to the current
    # network service resource
    #sl_dynamic_attr :related_resources do |resource|
      #resource.should_update? do
        #only retrieved once per instance
        # @related_resources == nil
      #end

      #resource.to_update do
        #related_resources = self.service.object_mask("mask[relatedResources.id]").getObject
        #related_resources.collect do |rel_res|
          #rel_res_service = self.service.object_with_id(rel_res['id'])
          #rel_res_service = rel_res_service.object_mask(self.default_object_mask)
          #NetworkServiceResource.new(self.softlayer_client, rel_res_service.getObject)
        #end    
      #end
    #end

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
                                                       #'dependentResources.id',
                                                       'frontendIpAddress',
                                                       'id',
                                                       'name',
                                                       'networkDevice.id',
                                                       #'relatedResources.id',
                                                       'sshUsername',
                                                       'type.type'
                                                      ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
