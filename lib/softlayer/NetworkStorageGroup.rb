module SoftLayer
  ##
  # Each SoftLayer NetworkStorageGroup instance provides information about
  # a storage product group and hosts allowed access.
  #
  # This class roughly corresponds to the entity SoftLayer_Network_Storage_Group
  # in the API.
  #
  class NetworkStorageGroup < ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader:
    # The friendly name of this group
    sl_attr :alias

    ##
    # :attr_reader: created_at
    # The date this group was created.
    sl_attr :created_at, 'createDate'

    ##
    # :attr_reader: created
    # The date this group was created.
    # DEPRECATION WARNING: This attribute is deprecated in favor of created_at
    # and will be removed in the next major release.
    sl_attr :created, 'createDate'

    ##
    # :attr_reader: modified_at
    # The date this group was modified.
    sl_attr :modified_at, 'modifyDate'

    ##
    # :attr_reader: modified
    # The date this group was modified.
    # DEPRECATION WARNING: This attribute is deprecated in favor of modified_at
    # and will be removed in the next major release.
    sl_attr :modified, 'modifyDate'

    ##
    # Retrieve the SoftLayer_Account which owns this group.
    # :call-seq:
    #   account(force_update=false)
    sl_dynamic_attr :account do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @account == nil
      end

      resource.to_update do
        account = self.service.getAccount
        Account.new(softlayer_client, account) unless account.empty?
      end
    end

    ##
    # Retrieve the allowed hosts list for this group.
    # :call-seq:
    #   allowed_hosts(force_update=false)
    sl_dynamic_attr :allowed_hosts do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @allowed_hosts == nil
      end

      resource.to_update do
        allowed_hosts = self.service.object_mask(NetworkStorageAllowedHost.default_object_mask).getAllowedHosts
        allowed_hosts.collect { |allowed_host| NetworkStorageAllowedHost.new(softlayer_client, allowed_host) unless allowed_host.empty? }.compact
      end
    end

    ##
    # Retrieve the network storage volumes this group is attached to.
    # :call-seq:
    #   attached_volumes(force_update=false)
    sl_dynamic_attr :attached_volumes do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @attached_volumes == nil
      end

      resource.to_update do
        attached_volumes = self.service.object_mask(NetworkStorage.default_object_mask).getAttachedVolumes
        attached_volumes.collect { |attached_volume| NetworkStorage.new(softlayer_client, attached_volume) unless attached_volume.empty? }.compact
      end
    end

    ##
    # Retrieve the IP address for for SoftLayer_Network_Storage_Allowed_Host objects within this group.
    # :call-seq:
    #   ip_address(force_update=false)
    sl_dynamic_attr :ip_address do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @ip_address == nil
      end

      resource.to_update do
        network_connection_details = self.service.getNetworkConnectionDetails
        network_connection_details["ipAddress"] unless network_connection_details.empty?
      end
    end

    ##
    # Retrieve the description of the SoftLayer_Network_Storage_OS_Type 
    # Operating System designation that this group was created for.
    # :call-seq:
    #   os_description(force_update=false)
    sl_dynamic_attr :os_description do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @os_description == nil
      end

      resource.to_update do
        os_type = self.service.getOsType
        os_type["description"] unless os_type.empty?
      end
    end

    ##
    # Retrieve the name of the SoftLayer_Network_Storage_OS_Type 
    # Operating System designation that this group was created for.
    # :call-seq:
    #   os_name(force_update=false)
    sl_dynamic_attr :os_name do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @os_name == nil
      end

      resource.to_update do
        os_type = self.service.getOsType
        os_type["name"] unless os_type.empty?
      end
    end

    ##
    # Retrieve the network resource this group is created on.
    # :call-seq:
    #   service_resource(force_update=false)
    sl_dynamic_attr :service_resource do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @service_resource == nil
      end

      resource.to_update do
        service_resource = self.service.object_mask(NetworkService.default_object_mask).getServiceResource
        NetworkService.new(softlayer_client, service_resource) unless service_resource.empty?
      end
    end

    ##
    # Retrieve the name of the SoftLayer_Network_Storage_Group_Type which describes this group.
    # :call-seq:
    #   type(force_update=false)
    sl_dynamic_attr :type do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @type == nil
      end

      resource.to_update do
        group_type = self.service.getGroupType
        group_type["name"]
      end
    end

    ##
    # Returns the service for interacting with this network storage through the network API
    #
    def service
      softlayer_client[:Network_Storage_Group].object_with_id(self.id)
    end

    protected

    def self.default_object_mask
      {
        "mask(SoftLayer_Network_Storage_Group)" => [
                                                    'alias',
                                                    'createDate',
                                                    'id',
                                                    'modifyDate'
                                                   ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
