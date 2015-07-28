#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  # Server is the base class for VirtualServer and BareMetalServer.
  # It implements some functionality common to both those classes.
  #
  # Server is an abstract class and you should not create them
  # directly.
  #
  # While VirtualServer and BareMetalServer each have analogs
  # in the SoftLayer API, those analogs do not share a direct
  # ancestry.  As a result there is no SoftLayer API analog
  # to this class.
  class Server  < SoftLayer::ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader:
    # The host name SoftLayer has stored for the server
    sl_attr :hostname

    ##
    # :attr_reader:
    # The domain name SoftLayer has stored for the server
    sl_attr :domain

    ##
    # :attr_reader: fqdn
    # A convenience attribute that combines the hostname and domain name
    sl_attr :fqdn, 'fullyQualifiedDomainName'

    ##
    # :attr_reader:
    # A convenience attribute that combines the hostname and domain name
    #
    # DEPRECATION WARNING: This attribute is deprecated in favor of fqdn
    # and will be removed in the next major release.
    sl_attr :fullyQualifiedDomainName

    ##
    # :attr_reader:
    # The data center where the server is located
    sl_attr :datacenter

    ##
    # :attr_reader: primary_public_ip
    # The IP address of the primary public interface for the server
    sl_attr :primary_public_ip, "primaryIpAddress"

    ##
    # :attr_reader: primary_private_ip
    # The IP address of the primary private interface for the server
    sl_attr :primary_private_ip, "primaryBackendIpAddress"

    ##
    # :attr_reader:
    # Notes about these server (for use by the customer)
    sl_attr :notes

    ##
    # The maximum network monitor query/response levels currently supported by the server
    # :call-seq:
    #   network_monitor_levels(force_update=false)
    sl_dynamic_attr :network_monitor_levels do |resource|
      resource.should_update? do
        @network_monitor_levels == nil
      end

      resource.to_update do
        NetworkMonitorLevels.new(self.service.getAvailableMonitoring)
      end
    end

    ##
    # A lsst of configured network monitors.
    # :call-seq:
    #   network_monitors(force_update=false)
    sl_dynamic_attr :network_monitors do |resource|
      resource.should_update? do
        @network_monitors == nil
      end

      resource.to_update do
        network_monitors_data = self.service.object_mask(NetworkMonitor.default_object_mask).getNetworkMonitors

        network_monitors_data.map! do |network_monitor|
          NetworkMonitor.new(softlayer_client, network_monitor) unless network_monitor.empty?
        end

        network_monitors_data.compact
      end
    end

    ##
    # :attr_reader:
    # The list of user customers notified on monitoring failures
    # :call-seq:
    #   notified_network_monitor_users(force_update=false)
    sl_dynamic_attr :notified_network_monitor_users do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @notified_network_monitor_users == nil
      end

      resource.to_update do
        notified_network_monitor_users_data = self.service.object_mask("mask[userId]").getMonitoringUserNotification

        notified_network_monitor_users = notified_network_monitor_users_data.collect do |notified_network_monitor_user|
          user_customer_service = softlayer_client[:User_Customer].object_with_id(notified_network_monitor_user['userId'])
          user_customer_data    = user_customer_service.object_mask(UserCustomer.default_object_mask).getObject

          UserCustomer.new(softlayer_client, user_customer_data) unless user_customer_data.empty?
        end

        notified_network_monitor_users.compact
      end
    end

    ##
    # Retrieve the primary network component
    # :call-seq:
    #   primary_network_component(force_update=false)
    sl_dynamic_attr :primary_network_component do |primary_component|
      primary_component.should_update? do
        return @primary_network_component == nil
      end

      primary_component.to_update do
        component_data = self.service.getPrimaryNetworkComponent();
        SoftLayer::NetworkComponent.new(self.softlayer_client, component_data)
      end
    end

    ##
    # Retrieve all software installed on current server
    # :call-seq:
    #   software(force_update=false)
    sl_dynamic_attr :software do |software|
      software.should_update? do
        @software == nil
      end

      software.to_update do
        software_data = self.service.object_mask(Software.default_object_mask).getSoftwareComponents
        software_data.collect { |sw| Software.new(self.softlayer_client, sw) unless sw.empty? }.compact
      end
    end

    ##
    # Construct a server from the given client using the network data found in +network_hash+
    #
    # Most users should not have to call this method directly. Instead you should access the
    # servers property of an Account object, or use methods like BareMetalServer#find_servers
    # or VirtualServer#find_servers
    #
    def initialize(softlayer_client, network_hash)
      if self.class == Server
        raise RuntimeError, "The Server class is an abstract base class and should not be instantiated directly"
      else
        super
      end
    end

    ##
    # Reboot the server.  This action is taken immediately.
    # Servers can be rebooted in three different ways:
    # :default_reboot - (Try soft, then hard) Attempts to reboot a server using the :os_reboot technique then, if that is not successful, tries the :power_cycle method
    # :os_reboot - (aka. soft reboot) instructs the server's host operating system to reboot
    # :power_cycle - (aka. hard reboot) The actual (for hardware) or metaphorical (for virtual servers) equivalent to pulling the plug on the server then plugging it back in.
    def reboot!(reboot_technique = :default_reboot)
      case reboot_technique
      when :default_reboot
        self.service.rebootDefault
      when :os_reboot
        self.service.rebootSoft
      when :power_cycle
        self.service.rebootHard
      else
        raise ArgumentError, "Unrecognized reboot technique in SoftLayer::Server#reboot!}"
      end
    end

    ##
    # Make an API request to SoftLayer and return the latest properties hash
    # for this object.
    def softlayer_properties(object_mask = nil)
      my_service = self.service

      if(object_mask)
        my_service = my_service.object_mask(object_mask)
      else
        my_service = my_service.object_mask(self.class.default_object_mask.to_sl_object_mask)
      end

      my_service.getObject()
    end

    ##
    # Change the notes of the server
    # raises ArgumentError if you pass nil as the notes
    def notes=(new_notes)
      raise ArgumentError, "The new notes cannot be nil" unless new_notes

      edit_template = {
        "notes" => new_notes
      }

      self.service.editObject(edit_template)
      self.refresh_details()
    end

    ##
    # Change the user metadata for the server.
    #
    def user_metadata=(new_metadata)
      raise ArgumentError, "Cannot set user metadata to nil" unless new_metadata
      self.service.setUserMetadata([new_metadata])
      self.refresh_details()
    end

    ##
    # Change the hostname of this server
    # Raises an ArgumentError if the new hostname is nil or empty
    #
    def set_hostname!(new_hostname)
      raise ArgumentError, "The new hostname cannot be nil" unless new_hostname
      raise ArgumentError, "The new hostname cannot be empty" if new_hostname.empty?

      edit_template = {
        "hostname" => new_hostname
      }

      self.service.editObject(edit_template)
      self.refresh_details()
    end

    ##
    # Change the domain of this server
    #
    # Raises an ArgumentError if the new domain is nil or empty
    # no further validation is done on the domain name
    #
    def set_domain!(new_domain)
      raise ArgumentError, "The new hostname cannot be nil" unless new_domain
      raise ArgumentError, "The new hostname cannot be empty" if new_domain.empty?

      edit_template = {
        "domain" => new_domain
      }

      self.service.editObject(edit_template)
      self.refresh_details()
    end

    ##
    # Returns the max port speed of the public network interfaces of the server taking into account
    # bound interface pairs (redundant network cards).
    def firewall_port_speed
      network_components = self.service.object_mask("mask[id,maxSpeed]").getFrontendNetworkComponents()
      max_speeds = network_components.collect { |component| component['maxSpeed'] }

      max_speeds.empty? ? 0 : max_speeds.max
    end

    ##
    # Change the current port speed of the server
    #
    # +new_speed+ is expressed Mbps and should be 0, 10, 100, or 1000.
    # Ports have a maximum speed that will limit the actual speed set
    # on the port.
    #
    # Set +public+ to +false+ in order to change the speed of the
    # private network interface.
    def change_port_speed(new_speed, public = true)
      if public
        self.service.setPublicNetworkInterfaceSpeed(new_speed)
      else
        self.service.setPrivateNetworkInterfaceSpeed(new_speed)
      end

      self.refresh_details()
      self
    end

    ##
    # Begins an OS reload on this server.
    #
    # The OS reload can wipe out the data on your server so this method uses a
    # confirmation mechanism built into the underlying SoftLayer API. If you
    # call this method once without a token, it will not actually start the
    # reload. Instead it will return a token to you. That token is good for
    # 10 minutes. If you call this method again and pass that token **then**
    # the OS reload will actually begin.
    #
    # If you wish to force the OS Reload and bypass the token safety mechanism
    # pass the token 'FORCE' as the first parameter. If you do so
    # the reload will proceed immediately.
    #
    def reload_os!(token = '', provisioning_script_uri = nil, ssh_keys = nil)
      configuration = {}

      configuration['customProvisionScriptUri'] = provisioning_script_uri if provisioning_script_uri
      configuration['sshKeyIds'] = ssh_keys if ssh_keys

      self.service.reloadOperatingSystem(token, configuration)
    end

    def to_s
      result = super
      if respond_to?(:hostname) then
        result.sub!('>', ", #{hostname}>")
      end
      result
    end

    protected

    # returns the default object mask for all servers
    # structured as a hash so that the classes BareMetalServer
    # and VirtualServer can use hash construction techniques to
    # specialize the mask for their use.
    def self.default_object_mask
      { "mask" => [
          'id',
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
          'networkComponents.primarySubnet[id, netmask, broadcastAddress, networkIdentifier, gateway]',
          'billingItem[id,recurringFee]',
          'hourlyBillingFlag',
          'tagReferences[id,tag[name,id]]',
          'networkVlans[id,vlanNumber,networkSpace]',
          'postInstallScriptUri'
        ]
      }
    end

  end # class Server
end # module SoftLayer
