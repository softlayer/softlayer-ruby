#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  #
  # VirtualServerOrder orders virtual servers using SoftLayer_Virtual_Guest::createObject.
  #
  # http://sldn.softlayer.com/reference/services/SoftLayer_Virtual_Guest/createObject
  #
  # +createObject+ allows you to order a virtual server by providing
  # a simple set of attributes and allows you to avoid much of the
  # complexity of the SoftLayer ordering system (see ProductPackage)
  #
  class VirtualServerOrder
    #--
    # Required Attributes
    # -------------------
    # The following attributes are required in order to successfully order
    # a virtual server
    #++

    # An instance of SoftLayer::Datacenter.  The server will be provisioned in that Datacenter.
    attr_accessor :datacenter

    # String, The hostname to assign to the new server
    attr_accessor :hostname

    # String, The domain (i.e. softlayer.com) for the new server
    attr_accessor :domain

    # Integer, The number of virtual CPU cores to include in the instance
    # Corresponds to +startCpus+ in the documentation for +createObject+
    attr_accessor :cores

    # Integer, The amount of RAM for the new server (specified in Gigabytes so a value of 4 is 4GB)
    # Corresponds to +maxMemory+ in the documentation for +createObject+
    attr_accessor :memory

    #--
    # These two options are mutually exclusive, but one of them must be provided.
    # If you provide both, the image_template will be added to the order and the
    # os_reference_code will be ignored
    #++

    # String, An OS reference code for the operating system to install on the virtual server
    # Corresponds to +operatingSystemReferenceCode+ in the +createObject+ documentation
    attr_accessor :os_reference_code

    # An instance of the SoftLayer::ImageTemplate class.  Represents the image template that should
    # be installed on the server.
    attr_accessor :image_template

    #--
    # Optional attributes
    #++

    # Boolean, If true, the virtual server will reside only on hosts with instances from this same account
    # Corresponds to +dedicatedAccountHostOnlyFlag+ in the +createObject+ documentation
    attr_accessor :dedicated_host_only

    # Array of Integer, Sizes (in gigabytes... so use 25 to get a 25GB disk) of disks to attach to this server
    # This roughly Corresponds to +blockDevices+ field in the +createObject+ documentation.
    # This attribute only allows you to configure the size of disks while +blockDevices+ allows
    # more configuration options
    attr_accessor :disks

    # Boolean, If true, an hourly server will be ordered, otherwise a monthly server will be ordered
    # Corresponds to +hourlyBillingFlag+ in the +createObject+ documentation
    attr_accessor :hourly

    # Integer, The maximum network interface card speed (in Mbps) for the new instance
    # Corresponds to +networkComponents.maxSpeed+ in the +createObject+ documentation
    attr_accessor :max_port_speed

    # Boolean, If true then the virtual server will only have a private network interface (and no public network interface)
    # Corresponds to +userData.value+ in the +createObject+ documentation
    attr_accessor :private_network_only

    # Integer, The id of the private VLAN this server should join
    # Corresponds to +primaryBackendNetworkComponent.networkVlan.id+ in the +createObject+ documentation
    attr_accessor :private_vlan_id

    # String, The URI of a post provisioning script to run on this server once it is created
    attr_accessor :provision_script_uri

    # String, The URI of a post provisioning script to run on this server once it is created
    #
    # DEPRECATION WARNING: This attribute is deprecated in favor of provision_script_uri
    # and will be removed in the next major release.
    attr_accessor :provision_script_URI

    # Integer, The id of the public VLAN this server should join
    # Corresponds to +primaryNetworkComponent.networkVlan.id+ in the +createObject+ documentation
    attr_accessor :public_vlan_id

    # Array of Strings, SSH keys to add to the root user's account.
    # Corresponds to +sshKeys+ in the +createObject+ documentation
    attr_accessor :ssh_key_ids

    # Boolean, If true the server will use a virtual hard drive, if false, data will be stored on a SAN disk
    # Corresponds to +localDiskFlag+ in the +createObject+ documentation
    attr_accessor :use_local_disk

    # String, User metadata associated with the instance
    # Corresponds to +primaryBackendNetworkComponent.networkVlan.id+ in the +createObject+ documentation
    attr_accessor :user_metadata

    # Hash, supplemental options - See https://sldn.softlayer.com/reference/datatypes/SoftLayer_Virtual_Guest_SupplementalCreateObjectOptions
    # Corresponds to +supplementalCreateObjectOptions+ in the +createObject+ documentation
    attr_accessor :supplementalCreateObjectOptions

    # Create a new order that works through the given client connection
    def initialize (client = nil)
      @softlayer_client = client || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !@softlayer_client
    end

    # Calls the SoftLayer API to verify that the template provided by this order is valid
    # This routine will return the order template generated by the API or will throw an exception
    #
    # This routine will not actually create a Virtual Server and will not affect billing.
    #
    # If you provide a block, it will receive the order template as a parameter and it
    # should return the order template you wish to forward to the server.
    def verify()
      order_template = virtual_guest_template
      order_template = yield order_template if block_given?

      @softlayer_client[:Virtual_Guest].generateOrderTemplate(order_template)
    end

    # Calls the SoftLayer API to place an order for a new virtual server based on the template in this
    # order. If this succeeds then you will be billed for the new Virtual Server.
    #
    # If you provide a block, it will receive the order template as a parameter and
    # should return an order template, **carefully** modified, that will be
    # sent to create the server
    def place_order!()
      order_template = virtual_guest_template
      order_template = yield order_template if block_given?

      virtual_server_hash = @softlayer_client[:Virtual_Guest].createObject(order_template)
      SoftLayer::VirtualServer.server_with_id(virtual_server_hash['id'], :client => @softlayer_client) if virtual_server_hash
    end

    protected

    # Returns a hash of the creation options formatted to be sent to
    # the SoftLayer API for either verification or completion
    def virtual_guest_template
      template = {
        "startCpus" => @cores.to_i,
        "maxMemory" => @memory.to_i * 1024,  # we let the user specify memory in GB, but the API expects maxMemory in MB.
        "hostname" => @hostname,
        "domain" => @domain,

        # Note : for the values below, we want to use the constants "true" and "false" not nil
        # the nil value (while false to Ruby) will not translate to XML properly
        "localDiskFlag" => !!@use_local_disk,
        "hourlyBillingFlag" => !!@hourly
      }

      template['dedicatedAccountHostOnlyFlag'] = true if @dedicated_host_only
      template['privateNetworkOnlyFlag'] = true if @private_network_only

      template['datacenter']                     = {"name" => @datacenter.name}     if @datacenter
      template['userData']                       = [{'value' => @user_metadata}]    if @user_metadata
      template['networkComponents']              = [{'maxSpeed'=> @max_port_speed}] if @max_port_speed
      template['postInstallScriptUri']           = @provision_script_URI.to_s       if @provision_script_URI
      template['postInstallScriptUri']           = @provision_script_uri.to_s       if @provision_script_uri
      template['primaryNetworkComponent']        = { "networkVlan" => { "id" => @public_vlan_id.to_i } } if @public_vlan_id
      template['primaryBackendNetworkComponent'] = { "networkVlan" => {"id" => @private_vlan_id.to_i } } if @private_vlan_id
      template['sshKeys']                        = @ssh_key_ids.collect { |ssh_key_id| {'id'=> ssh_key_id.to_i } } if @ssh_key_ids
      template['supplementalCreateObjectOptions'] = @supplementalCreateObjectOptions if @supplementalCreateObjectOptions

      if @image_template
        template['blockDeviceTemplateGroup'] = {"globalIdentifier" => @image_template.global_id}
      elsif @os_reference_code
        template['operatingSystemReferenceCode'] = @os_reference_code
      end

      if @disks && !@disks.empty?
        template['blockDevices'] = []

        # According to the documentation for +createObject+,
        # device number 1 is reserved for the SWAP disk of the computing instance.
        # So we assign device 0 and then assign the rest starting at index 2.
        @disks.each_with_index do |disk, index|
          device_id = (index >= 1) ? index + 1 : index
          template['blockDevices'].push({"device" => "#{device_id}", "diskImage" => {"capacity" => disk}})
        end
      end

      template
    end

    ##
    # The first time this is called it requests SoftLayer_Virtual_Guest::getCreateObjectOptions:
    # from the API and remembers the result. On subsequent calls it returns the remembered result.
    #
    # http://sldn.softlayer.com/reference/services/SoftLayer_Virtual_Guest/getCreateObjectOptions
    #
    def self.create_object_options(client = nil)
      softlayer_client = client || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      @@create_object_options ||= nil
      @@create_object_options = softlayer_client[:Virtual_Guest].getCreateObjectOptions() if !@@create_object_options
      @@create_object_options
    end

    #--
    # The following routines offer a way to query the SoftLayer API for values that are
    # valid in some of the fields of a Virtual Server order.  While the individual values
    # returned are all valid, it is still possible to create combinations of values which
    # the ordering system cannot accept.
    #++

    ##
    # Return a list of values that are valid for the :datacenter attribute
    def self.datacenter_options(client = nil)
      create_object_options(client)['datacenters'].collect { |datacenter_spec| Datacenter.datacenter_named(datacenter_spec['template']['datacenter']['name'], client) }.uniq
    end

    ##
    # Return a list of values that are valid for the :cores attribute
    def self.core_options(client = nil)
      create_object_options(client)['processors'].collect { |processor_spec| processor_spec['template']['startCpus'] }.uniq.sort!
    end

    ##
    # Return a list of values that are valid for the :memory attribute
    def self.memory_options(client = nil)
      create_object_options(client)['memory'].collect { |memory_spec| memory_spec['template']['maxMemory'].to_i / 1024}.uniq.sort!
    end

    ##
    # Return a list of values that are valid the array given to the :disks
    def self.disk_options(client = nil)
      create_object_options(client)['blockDevices'].collect { |block_device_spec| block_device_spec['template']['blockDevices'][0]['diskImage']['capacity']}.uniq.sort!
    end

    ##
    # Returns a list of the valid :os_reference_codes
    def self.os_reference_code_options(client = nil)
      create_object_options(client)['operatingSystems'].collect { |os_spec| os_spec['template']['operatingSystemReferenceCode'] }.uniq.sort!
    end

    ##
    # Returns a list of the :max_port_speeds
    def self.max_port_speed_options(client = nil)
      create_object_options(client)['networkComponents'].collect { |component_spec| component_spec['template']['networkComponents'][0]['maxSpeed'] }
    end
  end # class VirtualServerOrder
end # module SoftLayer
