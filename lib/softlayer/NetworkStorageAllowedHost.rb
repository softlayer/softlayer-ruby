module SoftLayer
  ##
  # Each SoftLayer NetworkStorageAllowedHost instance provides information about
  # a hosts allowed access to a storage product group.
  #
  # This class roughly corresponds to the entity SoftLayer_Network_Storage_Allowed_Host
  # in the API.
  #
  class NetworkStorageAllowedHost < ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader:
    # The name of allowed host, usually an IQN or other identifier
    sl_attr :name

    ##
    # The NetworkStorageGroup instances assigned to this host
    sl_dynamic_attr :assigned_groups do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @assigned_groups == nil
      end

      resource.to_update do
        assigned_groups = self.service.object_mask(NetworkStorageGroup.default_object_mask).getAssignedGroups
        assigned_groups.collect { |assigned_group| NetworkStorageGroup.new(softlayer_client, assigned_group) unless assigned_group.empty? }.compact
      end
    end

    ##
    # The NetworkStorage instances assigned to this host
    sl_dynamic_attr :assigned_volumes do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @assigned_volumes == nil
      end

      resource.to_update do
        assigned_volumes = self.service.object_mask(NetworkStorage.default_object_mask).getAssignedVolumes
        assigned_volumes.collect { |assigned_volume| NetworkStorage.new(softlayer_client, assigned_volume) unless assigned_volume.empty? }.compact
      end
    end

    ##
    # The NetworkStorageCredential instance used to access NetworkStorage for this host
    sl_dynamic_attr :credential do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @credential == nil
      end

      resource.to_update do
        credential = self.service.object_mask(NetworkStorageCredential.default_object_mask).getCredential
        NetworkStorageCredential.new(softlayer_client, credential) unless credential.empty?
      end
    end

    ##
    # Returns the service for interacting with this network storage through the network API
    #
    def service
      softlayer_client[:Network_Storage_Allowed_Host].object_with_id(self.id)
    end

    protected

    def self.default_object_mask
      {
        "mask(SoftLayer_Network_Storage_Allowed_Host)" => [
                                                           'id',
                                                           'name'
                                                          ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
