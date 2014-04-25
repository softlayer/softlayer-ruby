module SoftLayer
  class Server  < SoftLayer::ModelBase
    ##
    # Construct a server from the given client using the network data found in +network_hash+
    #
    # Most users should not have to call this method directly. Instead you should access the
    # servers property of an Account object, or use methods like find_servers in the +BareMetalServer+
    # and +VirtualServer+ classes.
    #
    def initialize(softlayer_client, network_hash)
      if self.class == Server
        raise RuntimeError, "The Server class is an abstract base class and should not be instantiated directly"
      else
        super
      end
    end

    ##
    # Returns the service responsible for handling the given
    # server.  In the base class (this one) the server is abstract
    # but subclasses implement this to return the appropriate service
    # from their client.
    #
    # @abstract
    def service
      raise RuntimeError, "this method is an abstract method in the Server base class"
    end

    ##
    # Reload the details of this server from the SoftLayer API
    def softlayer_properties(object_mask = nil)
      my_service = self.service

      if(object_mask)
        my_service = my_service.object_mask(object_mask)
      else
        my_service = my_service.object_mask(self.class.default_object_mask)
      end

      my_service.object_with_id(self.id).getObject()
    end

    ##
    # Change the hostname of this server (permanently)
    # Raises an ArgumentError if the new hostname is nil or empty
    def set_hostname!(new_hostname)
      raise ArgumentError.new("The new hostname cannot be nil") unless new_hostname
      raise ArgumentError.new("The new hostname cannot be empty") if new_hostname.empty?

      edit_template = {
        "hostname" => new_hostname
      }

      puts @sl_hash
      service.object_with_id(self.id).editObject(edit_template)
    end

    ##
    # Change the port speed of the server
    #
    # +new_speed+ should be 0, 10, 100, or 1000
    # set +public+ to +false+ in order to change the primary private
    # network interface instead of the primary public one.
    #
    def change_port_speed(new_speed, public = true)
      if public
        service.object_with_id(self.id).setPublicNetworkInterfaceSpeed(new_speed)
      else
        service.object_with_id(self.id).setPrivateNetworkInterfaceSpeed(new_speed)
      end

      self
    end

    def self.default_object_mask
      [ 'globalIdentifier',
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
