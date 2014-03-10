module SoftLayer
  class Server  < SoftLayer::ModelBase

    def initialize(softlayer_client, network_hash)
      if self.class == Server
        raise RuntimeError, "The Server class is an abstract base class and should not be instantiated directly"
      else
        super
      end
    end

    ##
    # service returns the service responsible for handling the given 
    # server.  In the base class (this one) the server is abstract
    # but subclasses implement this to return the appropriate service
    # from their client.
    def service
      raise RuntimeError, "this method is an abstract method in the Server base class"
    end
    
    ##
    # Change the port speed of the server
    #
    # new_speed should be 0, 10, 100, or 1000
    #
    def change_port_speed!(new_speed, public = true)
      if public
        service.object_with_id(self.id).setPublicNetworkInterfaceSpeed(new_speed)
      else
        service.object_with_id(self.id).setPrivateNetworkInterfaceSpeed(new_speed)
      end

      self
    end

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
