module SoftLayer
  class BareMetalServer < Server
    def self.default_object_mask
      sub_mask = ObjectMaskProperty.new("mask")
      sub_mask.type = "SoftLayer_Hardware_Server"
      sub_mask.subproperties = [
        'provisionDate', 
        'hardwareStatus',
        'memoryCapacity',
        'processorPhysicalCoreAmount',
        'networkManagementIpAddress',
        'networkComponents[id, status, speed, maxSpeed, name, ipmiMacAddress, ipmiIpAddress, macAddress, primaryIpAddress, port, primarySubnet]',
        'activeTransaction[id, transactionStatus[friendlyName,name]]',
        'hardwareChassis[id,name]']
      super + [sub_mask]
    end

    ##
    # Retrive the bare metal server with the given server ID from the 
    # SoftLayer API
    def self.bare_metal_server_with_id!(softlayer_client, server_id, options = {})
      if options.has_key?(:object_mask)
        object_mask = options[:object_mask]
      else
        object_mask = default_object_mask()        
      end

      server_data = softlayer_client["Hardware"].object_with_id(server_id).object_mask(object_mask).getObject()

      return BareMetalServer.new(softlayer_client, server_data)
    end
  end

end