module SoftLayer
  class Server  < SoftLayer::ModelBase
    def self.default_object_mask
      [ 'id',
        'globalIdentifier',
        'notes',
        'hostname',
        'domain',
        'fullyQualifiedDomainName',
        'datacenter',
        'primaryIpAddress',
        'primaryBackendIpAddress',
        { 'operatingSystem' => {
           'softwareLicense.softwareDescription' => ['manufacturer', 'name', 'version','referenceCode'],
           'passwords' => ['username','password'] } },
       'privateNetworkOnlyFlag',
       'userData',
       'datacenter',
       'networkComponents.primarySubnet[id, netmask, broadcastAddress, networkIdentifier, gateway]',
       'billingItem.recurringFee',
       'hourlyBillingFlag',
       'tagReferences[id,tag[name,id]]',
       'networkVlans[id,vlanNumber,networkSpace]',
       'postInstallScriptUri' ]
     end

     def to_s
      result = super
      if respond_to?(:hostname) then
        result.sub!('>', ", #{hostname}>")
      end
      result
    end
  end

end # SoftLayer module
