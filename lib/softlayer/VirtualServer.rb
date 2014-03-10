module SoftLayer
  class VirtualServer < Server
    def self.default_object_mask
      sub_mask = ObjectMaskProperty.new("mask")
      sub_mask.type = "SoftLayer_Virtual_Guest"
      sub_mask.subproperties = [
       'createDate',
       'modifyDate',
       'provisionDate',
       'dedicatedAccountHostOnlyFlag',
       'lastKnownPowerState.name',
       'powerState',
       'status',
       'maxCpu',
       'maxMemory',
       'activeTransaction[id, transactionStatus[friendlyName,name]]',
       'networkComponents[id, status, speed, maxSpeed, name, macAddress, primaryIpAddress, port, primarySubnet]',
       'lastOperatingSystemReload.id',
       'blockDevices',
       'blockDeviceTemplateGroup[id, name, globalIdentifier]' ]
      super + [sub_mask]
    end #default_object_mask


    ## 
    # Retrive the virtual server with the given server ID from the API
    #
    def self.virtual_server_with_id!(softlayer_client, server_id, options = {})
      if options.has_key?(:object_mask)
        object_mask = options[:object_mask]
      else
        object_mask = default_object_mask()        
      end

      server_data = softlayer_client["Virtual_Guest"].object_with_id(server_id).object_mask(object_mask).getObject()

      return VirtualServer.new(softlayer_client, server_data)
    end
  end #class VirtualServer
end