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

    # String, short name of the data center that will house the new virtual server (e.g. "dal05" or "sea01")
    # Corresponds to +datacenter.name+ in the documentation for createObject
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
    # These two options are mutually exclusive, but one or the other must be provided.
    # If you provide both, the image_global_id will be added to the order and the os_reference_code will be ignored
    #++

    # String, An OS reference code for the operating system to install on the virtual server
    # Corresponds to +operatingSystemReferenceCode+ in the +createObject+ documentation
    attr_accessor :os_reference_code

    # String, The globalIdentifier of a disk image to put on the newly created server
    # Corresponds to +blockDeviceTemplateGroup.globalIdentifier+ in the +createObject+ documentation
    attr_accessor :image_global_id

    #--
    # Optional attributes
    #++

    # Boolean, If true, an hourly server will be ordered, otherwise a monthly server will be ordered
    # Corresponds to +hourlyBillingFlag+ in the +createObject+ documentation
    attr_accessor :hourly

    # Boolean, If true the server will use a virtual hard drive, if false, data will be stored on a SAN disk
    # Corresponds to +localDiskFlag+ in the +createObject+ documentation
    attr_accessor :use_local_disk

    # Boolean, If true, the virtual server will reside only on hosts with instances from this same account
    # Corresponds to +dedicatedAccountHostOnlyFlag+ in the +createObject+ documentation
    attr_accessor :dedicated_host_only

    # Integer, The id of the public VLAN this server should join
    # Corresponds to +primaryNetworkComponent.networkVlan.id+ in the +createObject+ documentation
    attr_accessor :public_vlan_id

    # Integer, The id of the private VLAN this server should join
    # Corresponds to +primaryBackendNetworkComponent.networkVlan.id+ in the +createObject+ documentation
    attr_accessor :private_vlan_id

    # Array of Integer, Sizes (in gigabytes... so use 25 to get a 25GB disk) of disks to attach to this server
    # This roughly Corresponds to +blockDevices+ field in the +createObject+ documentation.
    # This attribute only allows you to configure the size of disks while +blockDevices+ allows
    # more configuration options
    attr_accessor :disks

    # Array of Strings, SSH keys to add to the root user's account.
    # Corresponds to +sshKeys+ in the +createObject+ documentation
    attr_accessor :ssh_key_ids

    # String, The URI of a post provisioning script to run on this server once it is created
    attr_accessor :provision_script_URI

    # Boolean, If true then the virtual server will only have a private network interface (and no public network interface)
    # Corresponds to +userData.value+ in the +createObject+ documentation
    attr_accessor :private_network_only

    # String, User metadata associated with the instance
    # Corresponds to +primaryBackendNetworkComponent.networkVlan.id+ in the +createObject+ documentation
    attr_accessor :user_metadata

    # Integer (Should be 10, 100, or 1000), The maximum network interface card speed (in Mbps) for the new instance
    # Corresponds to +networkComponents.maxSpeed+ in the +createObject+ documentation
    attr_accessor :max_port_speed

    # Create a new order that works thorugh the given client connection
    def initialize (client)
      @softlayer_client = client
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

      @softlayer_client["Virtual_Guest"].generateOrderTemplate(order_template)
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

      virtual_server_hash = @softlayer_client["Virtual_Guest"].createObject(order_template)
      SoftLayer::VirtualServer.server_with_id(@softlayer_client, virtual_server_hash["id"]) if virtual_server_hash
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

      template["dedicatedAccountHostOnlyFlag"] = true if @dedicated_host_only
      template["privateNetworkOnlyFlag"] = true if @private_network_only

      template["datacenter"] = {"name" => @datacenter} if @datacenter
      template['userData'] = [{'value' => @user_metadata}] if @user_metadata
      template['networkComponents'] = [{'maxSpeed'=> @max_port_speed}] if @max_port_speed
      template['postInstallScriptUri'] = @provision_script_URI.to_s if @provision_script_URI
      template['sshKeys'] = @ssh_key_ids.collect { |ssh_key_id| {'id'=> ssh_key_id.to_i } } if @ssh_key_ids
      template['primaryNetworkComponent'] = { "networkVlan" => { "id" => @public_vlan_id.to_i } } if @public_vlan_id
      template["primaryBackendNetworkComponent"] = { "networkVlan" => {"id" => @private_vlan_id.to_i } } if @private_vlan_id

      if @image_global_id
          template["blockDeviceTemplateGroup"] = {"globalIdentifier" => @image_global_id}
      elsif @os_reference_code
          template["operatingSystemReferenceCode"] = @os_reference_code
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
    # The first time this is called it requests SoftLayer_Virtual_Guest::getCreateObjectOptions
    # from the API and remembers the result. On subsequent calls it returns the remembered result.
    def self.create_object_options(client)
      @@create_object_options ||= client["Virtual_Guest"].getCreateObjectOptions()
    end

    #--
    # The following routines offer a way to query the SoftLayer API for values that are
    # valid in some of the fields of a Virtual Server order.  While the individual values
    # returned are all valid, it is still possible to create combinations of values which
    # the ordering system cannot accept.
    #++

    ##
    # Return a list of values that are valid for the :cores attribute in a Virtual Server order.
    def self.core_options(client)
      create_object_options(client)["processors"].collect { |processor_spec| processor_spec['template']['startCpus'] }.uniq.sort!
    end

    ##
    # Return a list of values that are valid for the :memory attribute in a Virtual Server order.
    def self.memory_options(client)
      create_object_options(client)["memory"].collect { |memory_spec| memory_spec['template']['maxMemory'].to_i / 1024}.uniq.sort!
    end

    ##
    # Return a list of values that are valid the array given to the :disks attribute of a Virtual Server order
    def self.disk_options(client)
      create_object_options(client)["blockDevices"].collect { |block_device_spec| block_device_spec['template']['blockDevices'][0]['diskImage']['capacity']}.uniq.sort!
    end

    ##
    # Returns a list of the os_refrence_codes that are valid in a Virtual Server Order.
    def self.os_reference_code_options(client)
      create_object_options(client)["operatingSystems"].collect { |os_spec| os_spec['template']['operatingSystemReferenceCode'] }.uniq.sort!
    end

    ##
    # Returns a list of the max_port_speeds that are valid in a Virtual Server Order.
    def self.max_port_speed_options(client)
      create_object_options(client)["networkComponents"].collect { |component_spec| component_spec['template']['networkComponents'][0]['maxSpeed'] }
    end
  end # class VirtualServerOrder
end # module SoftLayer
