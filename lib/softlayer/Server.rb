#
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

module SoftLayer
  class Server  < SoftLayer::ModelBase
    ##
    # Construct a server from the given client using the network data found in +network_hash+
    #
    # Most users should not have to call this method directly. Instead you should access the
    # servers property of an Account object, or use methods like find_servers in the +BareMetalServer+
    # and +VirtualServer+ classes.
    #
    # @abstract
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
      raise RuntimeError, "This method is an abstract method in the Server base class"
    end

    ##
    # properties used when reloading this object from teh softlayer API
    def softlayer_properties(object_mask = nil)
      my_service = self.service

      if(object_mask)
        my_service = my_service.object_mask(object_mask)
      else
        my_service = my_service.object_mask(self.class.default_object_mask.to_sl_object_mask)
      end

      my_service.object_with_id(self.id).getObject()
    end

    ##
    # Change the notes of the server
    # raises ArgumentError if you pass nil as the notes
    def notes=(new_notes)
      raise ArgumentError.new("The new notes cannot be nil") unless new_notes

      edit_template = {
        "notes" => new_notes
      }

      service.object_with_id(self.id).editObject(edit_template)
    end

    def user_metadata=(new_metadata)
      raise ArgumentError.new("Cannot set user metadata to nil") unless new_metadata

      service.object_with_id(self.id).setUserMetadata([new_metadata])
    end

    ##
    # Change the hostname of this server
    # Raises an ArgumentError if the new hostname is nil or empty
    #
    def set_hostname!(new_hostname)
      raise ArgumentError.new("The new hostname cannot be nil") unless new_hostname
      raise ArgumentError.new("The new hostname cannot be empty") if new_hostname.empty?

      edit_template = {
        "hostname" => new_hostname
      }

      service.object_with_id(self.id).editObject(edit_template)
    end

    ##
    # Change the domain of this server
    # Raises an ArgumentError if the new domain is nil or empty
    # no further validation is done on the domain name
    #
    def set_domain!(new_domain)
      raise ArgumentError.new("The new hostname cannot be nil") unless new_domain
      raise ArgumentError.new("The new hostname cannot be empty") if new_domain.empty?

      edit_template = {
        "domain" => new_domain
      }

      service.object_with_id(self.id).editObject(edit_template)
    end

    ##
    # Change the current port speed of the server
    #
    # +new_speed+ should be 0, 10, 100, or 1000 and the actual
    # speed of the port will be limited by the current maximum port
    # speed for the server.
    #
    # Set +public+ to +false+ in order to change the speed of the
    # primary private network interface instead of the primary
    # public one.
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
      { "mask" => [
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
              'passwords' => ['username','password']
            }
          },
          'privateNetworkOnlyFlag',
          'userData',
          'datacenter',
          'networkComponents.primarySubnet[id, netmask, broadcastAddress, networkIdentifier, gateway]',
          'billingItem.recurringFee',
          'hourlyBillingFlag',
          'tagReferences[id,tag[name,id]]',
          'networkVlans[id,vlanNumber,networkSpace]',
          'postInstallScriptUri'
        ]
      }
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
