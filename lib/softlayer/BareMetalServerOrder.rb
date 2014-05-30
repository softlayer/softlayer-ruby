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
  # This class allows you to order a Bare Metal Server by providing
  # a simple set of attributes for the newly created server. The
  # SoftLayer system will select a server that matches the attributes
  # provided and provision it or will report an error.
  #
  # If you wish to have more exacting control over the set of options
  # that go into configuring the server, please see the
  # BareMetalServerOrder_Package class.
  #
  # This class creates the server with the SoftLayer_Hardware::createObject 
  # method.
  #
  # http://sldn.softlayer.com/reference/services/SoftLayer_Hardware/createObject
  #
  # Reading that documentation may help you understand the options presented here.
  #
  class BareMetalServerOrder
    #--
    # Required Attributes
    # -------------------
    # The following attributes are required in order to successfully order
    # a Bare Metal Instance
    #++

    # String, The hostname to assign to the new server
    attr_accessor :hostname

    # String, The domain (i.e. softlayer.com) for the new server
    attr_accessor :domain

    # Integer, The number of cpu cores to include in the instance
    # Corresponds to +processorCoreAmount+ in the documentation for +createObject+
    attr_accessor :cores

    # Integer, The amount of RAM for the new server (specified in Gigabytes so a value of 4 is 4GB)
    # Corresponds to +memoryCapacity+ in the documentation for +createObject+
    attr_accessor :memory

    # String, An OS reference code for the operating system to install on the server
    # Corresponds to +operatingSystemReferenceCode+ in the +createObject+ documentation
    attr_accessor :os_reference_code

    #--
    # Optional attributes
    #++

    # String, short name of the data center that will house the new Bare Metal Instance (e.g. "dal05" or "sea01")
    # Corresponds to +datacenter.name+ in the documentation for createObject
    attr_accessor :datacenter

    # Boolean, If true, an hourly server will be ordered, otherwise a monthly server will be ordered
    # Corresponds to +hourlyBillingFlag+ in the +createObject+ documentation
    attr_accessor :hourly

    # Integer, The id of the public VLAN this server should join
    # Corresponds to +primaryNetworkComponent.networkVlan.id+ in the +createObject+ documentation
    attr_accessor :public_vlan_id

    # Integer, The id of the private VLAN this server should join
    # Corresponds to +primaryBackendNetworkComponent.networkVlan.id+ in the +createObject+ documentation
    attr_accessor :private_vlan_id

    # Array of Integer, Sizes (in gigabytes... so use 25 to get a 25GB disk) of disks to attach to this server
    # This roughly Corresponds to +hardDrives+ field in the +createObject+ documentation.
    attr_accessor :disks

    # Array of Strings, SSH keys to add to the root user's account.
    # Corresponds to +sshKeys+ in the +createObject+ documentation
    attr_accessor :ssh_key_ids

    # Object responding to to_s and providing a valid URI, The URI of a post provisioning script to run on
    # this server once it is created.
    # Corresponds to +postInstallScriptUri+ in the +createObject+ documentation
    attr_accessor :provision_script_URI

    # Boolean, If true then the server will only have a private network interface (and no public network interface)
    # Corresponds to +privateNetworkOnlyFlag+ in the +createObject+ documentation
    attr_accessor :private_network_only

    # String, User metadata associated with the instance
    # Corresponds to +userData.value+ in the +createObject+ documentation
    attr_accessor :user_metadata

    # Integer (Should be 10, 100, or 1000), The maximum network interface card speed (in Mbps) for the new instance
    # Corresponds to +networkComponents.maxSpeed+ in the +createObject+ documentation
    attr_accessor :max_port_speed

    ##
    # Create a new order that works thorugh the given client connection
    def initialize (client)
      @softlayer_client = client
    end

    ##
    # Calls the SoftLayer API to verify that the template provided by this order is valid
    # This routine will return the order template generated by the API or will throw an exception
    #
    # This routine will not actually create a Bare Metal Instance and will not affect billing.
    #
    # If you provide a block, it will receive the order template as a parameter and
    # the block may make changes to the template before it is submitted.
    def verify()
      order_template = hardware_instance_template
      order_template = yield order_template if block_given?

      @softlayer_client["Hardware"].generateOrderTemplate(order_template)
    end

    ##
    # Calls the SoftLayer API to place an order for a new server based on the template in this
    # order. If this succeeds then you will be billed for the new server.
    #
    # If you provide a block, it will receive the order template as a parameter and
    # the block may make changes to the template before it is submitted.
    def place_order!()
      order_template = hardware_instance_template
      order_template = yield order_template if block_given?

      server_hash = @softlayer_client["Hardware"].createObject(order_template)
      SoftLayer::BareMetalServer.server_with_id(@softlayer_client, server_hash["id"]) if server_hash
    end

    protected

    ##
    # Returns a hash of the creation options formatted to be sent to
    # the SoftLayer API for either verification or completion
    def hardware_instance_template
      template = {
        "processorCoreAmount" => @cores.to_i,
        "memoryCapacity" => @memory.to_i,
        "hostname" => @hostname,
        "domain" => @domain,
        "operatingSystemReferenceCode" => @os_reference_code,

        # Note : for the values below, we want to use the constants "true" and "false" not nil
        # the nil value (while false to Ruby) will not translate to XML properly
        "localDiskFlag" => !!@use_local_disk,
        "hourlyBillingFlag" => !!@hourly
      }

      template["privateNetworkOnlyFlag"] = true if @private_network_only

      template["datacenter"] = {"name" => @datacenter} if @datacenter
      template['userData'] = [{'value' => @user_metadata}] if @user_metadata
      template['networkComponents'] = [{'maxSpeed'=> @max_port_speed}] if @max_port_speed
      template['postInstallScriptUri'] = @provision_script_URI.to_s if @provision_script_URI
      template['sshKeys'] = @ssh_key_ids.collect { |ssh_key| {'id'=> ssh_key.to_i } } if @ssh_key_ids
      template['primaryNetworkComponent'] = { "networkVlan" => { "id" => @public_vlan_id.to_i } } if @public_vlan_id
      template["primaryBackendNetworkComponent"] = { "networkVlan" => {"id" => @private_vlan_id.to_i } } if @private_vlan_id

      if @disks && !@disks.empty?
        template['hardDrives'] = @disks.collect do |disk|
          {"capacity" => disk.to_i}
        end
      end

      template
    end

    ##
    # The first time this is called it requests SoftLayer_Hardware::getCreateObjectOptions
    # from the API and remembers the result. On subsequent calls it returns the remembered result.
    def self.create_object_options(client)
      @@create_object_options ||= client["Hardware"].getCreateObjectOptions()
    end
    
    ##
    # Return a list of values that are valid for the :datacenter attribute
    def self.datacenter_options(client)
      create_object_options(client)["datacenters"].collect { |datacenter_spec| datacenter_spec['template']['datacenter']["name"] }.uniq.sort!
    end
    
    def self.core_options(client)
      create_object_options(client)["processors"].collect { |processor_spec| processor_spec['template']['processorCoreAmount'] }.uniq.sort!
    end

    ##
    # Return a list of values that are valid the array given to the :disks
    def self.disk_options(client)
      create_object_options(client)["hardDrives"].collect { |disk_spec| disk_spec['template']['hardDrives'][0]['capacity'].to_i}.uniq.sort!
    end

    ##
    # Returns a list of the valid :os_refrence_codes
    def self.os_reference_code_options(client)
      create_object_options(client)["operatingSystems"].collect { |os_spec| os_spec['template']['operatingSystemReferenceCode'] }.uniq.sort!
    end

    ##
    # Returns a list of the :max_port_speeds
    def self.max_port_speed_options(client)
      create_object_options(client)["networkComponents"].collect { |component_spec| component_spec['template']['networkComponents'][0]['maxSpeed'] }
    end    

  end # class BareMetalServerOrder
end # module SoftLayer
