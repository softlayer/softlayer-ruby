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
  end

end