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
  end #class VirtualServer
end