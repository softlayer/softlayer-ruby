#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # Each SoftLayer SoftwarePassword instance provides information about
  # a user's password associated with a SoftLayer Software instance.
  #
  # This class roughly corresponds to the entity SoftLayer_Software_Component_Password
  # in the API.
  #
  class SoftwarePassword < ModelBase
    include ::SoftLayer::DynamicAttribute
    
    ##
    # :attr_reader: created
    # The date this username/password pair was created.
    sl_attr :created, 'createDate'

    ##
    # :attr_reader: modified
    # The date of the last modification to this username/password pair.
    sl_attr :modified, 'modifyDate'

    ##
    # :attr_reader:
    # A note string stored for this username/password pair.
    sl_attr :notes

    ##
    # :attr_reader:
    # The password part of the username/password pair.
    sl_attr :password

    ##
    # :attr_reader:
    sl_attr :port

    ##
    # The username part of the username/password pair.
    sl_attr :username

    ##
    # Updates the password for the current software user.
    #
    def password=(password)
      raise ArgumentError, "The new password cannot be nil"   unless password
      raise ArgumentError, "The new password cannot be empty" if password.empty?

      self.service.editObject({ "password" => password.to_s })
      self.refresh_details()
    end

    ##
    # Retrieve a list of software passwords from application delivery controllers.
    #
    # The options parameter should contain:
    #
    # <b>+:client+</b> - The client used to connect to the API
    #
    # If no client is given, then the routine will try to use Client.default_client
    # If no client can be found the routine will raise an error.
    #
    # You may filter the list returned by adding options:
    # * <b>+:datacenter+</b>    (string/array) - Include software passwords from application delivery controllers matching this datacenter
    # * <b>+:name+</b>          (string/array) - Include software passwords from application delivery controllers that matches this name
    # * <b>+:tags+</b>          (string/array  - Include software passwords from application delivery controllers that matches these tags
    # * <b>+:username+</b>      (string/array) - Include software passwords that match this username
    #
    def self.find_passwords_for_application_delivery_controllers(options_hash = {})
      softlayer_client = options_hash[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      if(options_hash.has_key? :application_delivery_controller_object_filter)
        application_delivery_controller_object_filter = options_hash[:application_delivery_controller_object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless application_delivery_controller_object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        application_delivery_controller_object_filter = ObjectFilter.new()
      end

      if(options_hash.has_key? :software_password_object_filter)
        software_password_object_filter = options_hash[:software_password_object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless software_password_object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        software_password_object_filter = ObjectFilter.new()
      end

      option_to_filter_path = {
        :app_deliv_controller => {
          :advanced_mode     => "applicationDeliveryControllers.advancedModeFlag",
          :datacenter        => "applicationDeliveryControllers.datacenter.name",
          :name              => "applicationDeliveryControllers.name",
          :tags              => "applicationDeliveryControllers.tagReferences.tag.name"
        },
        :software_password    => {
          :username        => "password.username"
        }
      }

      application_delivery_controller_object_filter.modify { |filter| filter.accept(option_to_filter_path[:app_deliv_controller][:advanced_mode]).when_it is(true) }

      option_to_filter_path[:app_deliv_controller].each do |option, filter_path|
        next if option == :advanced_mode

        if options_hash[option]
          application_delivery_controller_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option]) }
        end
      end

      option_to_filter_path[:software_password].each do |option, filter_path|
        software_password_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option]) } if options_hash[option]
      end

      account_service = softlayer_client[:Account]
      account_service = account_service.object_filter(application_delivery_controller_object_filter) unless application_delivery_controller_object_filter.empty?
      account_service = account_service.object_mask("mask[id]")

      application_delivery_controller_data = account_service.getApplicationDeliveryControllers
      software_passwords                   = application_delivery_controller_data.collect do |application_delivery_controller|
        application_delivery_controller_service = softlayer_client[:Network_Application_Delivery_Controller].object_with_id(application_delivery_controller['id'])
        application_delivery_controller_service = application_delivery_controller_service.object_filter(software_password_object_filter) unless software_password_object_filter.empty?
        application_delivery_controller_service = application_delivery_controller_service.object_mask(SoftwarePassword.default_object_mask)
        application_delivery_controller_service = application_delivery_controller_service.object_mask(options_hash[:software_password_object_mask]) if options_hash[:software_password_object_mask]

        software_password_data = application_delivery_controller_service.getPassword
        SoftwarePassword.new(softlayer_client, software_password_data) unless software_password_data.empty?
      end

      software_passwords.compact
    end

    ##
    # Retrieve a list of software passwords from vlan firewalls management credentials.
    #
    # The options parameter should contain:
    #
    # <b>+:client+</b> - The client used to connect to the API
    #
    # If no client is given, then the routine will try to use Client.default_client
    # If no client can be found the routine will raise an error.
    #
    # You may filter the list returned by adding options:
    # * <b>+:datacenter+</b>    (string/array) - Include software passwords from vlan firewalls matching this datacenter
    # * <b>+:vlan_names+</b>    (string/array) - Include software passwords from vlans that matches these names
    # * <b>+:vlan_numbers+</b>  (string/array) - Include software passwords from vlans that matches these numbers
    # * <b>+:vlan_space+</b>    (symbol)       - Include software passwords from vlans that match this space
    # * <b>+:vlan_tags+</b>     (string/array) - Include software passwords from vlans that matches these tags
    # * <b>+:vlan_fw_fqdn+</b>  (string/array) - Include software passwords from vlan firewalls that match this fqdn
    # * <b>+:vlan_fw_tags+</b>  (string/array) - Include software passwords from vlan firewalls that matches these tags
    # * <b>+:vlan_fw_type+</b>  (string/array) - Include software passwords from vlan firewalls that match this type
    # * <b>+:username+</b>      (string/array) - Include software passwords that match this username
    #
    def self.find_passwords_for_vlan_firewalls(options_hash = {})
      softlayer_client = options_hash[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      if(options_hash.has_key? :vlan_object_filter)
        vlan_object_filter = options_hash[:vlan_object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless vlan_object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        vlan_object_filter = ObjectFilter.new()
      end

      if(options_hash.has_key? :vlan_firewall_object_filter)
        vlan_firewall_object_filter = options_hash[:vlan_firewall_object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless vlan_firewall_object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        vlan_firewall_object_filter = ObjectFilter.new()
      end

      if(options_hash.has_key? :software_password_object_filter)
        software_password_object_filter = options_hash[:software_password_object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless software_password_object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        software_password_object_filter = ObjectFilter.new()
      end

      filter_label = {
        :all     => 'networkVlans',
        :private => 'privateNetworkVlans',
        :public  => 'publicNetworkVlans'
      }

      option_to_filter_path = {
        :software_password => {
          :username        => "managementCredentials.username"
          },
        :vlan              => {
          :vlan_dedicated_fw => lambda { |vlan_space| return [ filter_label[vlan_space], '.', 'dedicatedFirewallFlag' ].join  },
          :vlan_names        => lambda { |vlan_space| return [ filter_label[vlan_space], '.', 'name' ].join                   },
          :vlan_numbers      => lambda { |vlan_space| return [ filter_label[vlan_space], '.', 'vlanNumber' ].join             },
          :vlan_tags         => lambda { |vlan_space| return [ filter_label[vlan_space], '.', 'tagReferences.tag.name' ].join }
        },
        :vlan_firewall     => {
          :vlan_fw_datacenter => "networkVlanFirewall.datacenter.name",
          :vlan_fw_fqdn       => "networkVlanFirewall.fullyQualifiedDomainName",
          :vlan_fw_tags       => "networkVlanFirewall.tagReferences.tag.name",
          :vlan_fw_type       => "networkVlanFirewall.firewallType"
        }
      }

      if options_hash[:vlan_space] && ! filter_label.keys.include?(options_hash[:vlan_space])
        raise "Expected one of :all, :private, or :public for option :vlan_space in #{__method__}"
      end

      option_to_filter_path[:software_password].each do |option, filter_path|
        software_password_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option]) } if options_hash[option]
      end

      vlan_space = options_hash[:vlan_space] || :all

      option_to_filter_path[:vlan].keys.each do |option|
        vlan_object_filter.modify { |filter| filter.accept(option_to_filter_path[:vlan][option].call(vlan_space)).when_it is(1) } if option == :vlan_dedicated_fw

        if options_hash[option] && option != :vlan_dedicated_fw
          vlan_object_filter.modify { |filter| filter.accept(option_to_filter_path[:vlan][option].call(vlan_space)).when_it is(options_hash[option]) }
        end
      end

      option_to_filter_path[:vlan_firewall].each do |option, filter_path|
        vlan_firewall_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option]) } if options_hash[option]
      end

      account_service = softlayer_client[:Account]
      account_service = account_service.object_filter(vlan_object_filter) unless vlan_object_filter.empty?
      account_service = account_service.object_mask("mask[id]")

      case vlan_space
      when :all
        vlan_data = account_service.getNetworkVlans
      when :private
        vlan_data = account_service.getPrivateNetworkVlans
      when :public
        vlan_data = account_service.getPublicNetworkVlans
      end

      vlan_fw_passwords = vlan_data.collect do |vlan|
        vlan_service = softlayer_client[:Network_Vlan].object_with_id(vlan['id'])
        vlan_service = vlan_service.object_filter(vlan_firewall_object_filter) unless vlan_firewall_object_filter.empty?
        vlan_service = vlan_service.object_mask("mask[id]")

        vlan_fw = vlan_service.getNetworkVlanFirewall

        unless vlan_fw.empty?
          vlan_fw_service = softlayer_client[:Network_Vlan_Firewall].object_with_id(vlan_fw['id'])
          vlan_fw_service = vlan_fw_service.object_filter(software_password_object_filter) unless software_password_object_filter.empty?
          vlan_fw_service = vlan_fw_service.object_mask(SoftwarePassword.default_object_mask)
          vlan_fw_service = vlan_fw_service.object_mask(options_hash[:software_password_object_mask]) if options_hash[:software_password_object_mask]

          vlan_fw_password_data = vlan_fw_service.getManagementCredentials
          SoftwarePassword.new(softlayer_client, vlan_fw_password_data) unless vlan_fw_password_data.empty?
        end
      end

      vlan_fw_passwords.compact
    end

    ##
    # Retrieve a list of software passwords from software on hardware devices.
    #
    # The options parameter should contain:
    #
    # <b>+:client+</b> - The client used to connect to the API
    #
    # If no client is given, then the routine will try to use Client.default_client
    # If no client can be found the routine will raise an error.
    #
    # You may filter the list returned by adding options:
    # * <b>+:datacenter+</b>    (string/array) - Include software passwords from software on hardware matching this datacenter
    # * <b>+:description+</b>   (string/array) - Include software passwords from software that matches this description
    # * <b>+:domain+</b>        (string/array) - Include software passwords from software on hardware matching this domain
    # * <b>+:hardware_type+</b> (symbol)       - Include software passwords from software on hardware matching this hardware type
    # * <b>+:hostname+</b>      (string/array) - Include software passwords from software on hardware matching this hostname
    # * <b>+:manufacturer+</b>  (string/array) - Include software passwords from software that matches this manufacturer
    # * <b>+:name+</b>          (string/array) - Include software passwords from software that matches this name
    # * <b>+:username+</b>      (string/array) - Include software passwords for username matching this username
    #
    # You may use the following properties to provide hardware or software object filter instances:
    # * <b>+:hardware_object_filter+</b>          (ObjectFilter) - Include software passwords from software on hardware that matches the criteria of this object filter
    # * <b>+:software_object_filter+</b>          (ObjectFilter) - Include software passwords from software that matches the criteria of this object filter
    # * <b>+:software_password_object_filter*</b> (ObjectFilter) - Include software passwords that match the criteria of this object filter
    # * <b>+:software_password_object_mask+</b>   (string)       - Include software password properties that matches the criteria of this object mask
    #
    def self.find_passwords_for_software_on_hardware(options_hash = {})
      softlayer_client = options_hash[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      if(options_hash.has_key? :hardware_object_filter)
        hardware_object_filter = options_hash[:hardware_object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless hardware_object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        hardware_object_filter = ObjectFilter.new()
      end

      if(options_hash.has_key? :software_object_filter)
        software_object_filter = options_hash[:software_object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless software_object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        software_object_filter = ObjectFilter.new()
      end

      if(options_hash.has_key? :software_password_object_filter)
        software_password_object_filter = options_hash[:software_password_object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless software_password_object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        software_password_object_filter = ObjectFilter.new()
      end

      filter_label = {
        :bare_metal_instance => "bareMetalInstances",
        :hardware            => "hardware",
        :network_hardware    => "networkHardware",
        :router              => "routers"
      }

      option_to_filter_path = {
        :hardware          => {
          :datacenter        => lambda { |hardware_type| return [ filter_label[hardware_type], '.datacenter.name' ].join        },
          :domain            => lambda { |hardware_type| return [ filter_label[hardware_type], '.domain' ].join                 },
          :hostname          => lambda { |hardware_type| return [ filter_label[hardware_type], '.hostname' ].join               },
          :tags              => lambda { |hardware_type| return [ filter_label[hardware_type], '.tagReferences.tag.name' ].join }
        },
        :software          => {
          :description     => "softwareComponents.softwareDescription.longDescription",
          :manufacturer    => "softwareComponents.softwareDescription.manufacturer",
          :name            => "softwareComponents.softwareDescription.name",
          :username        => "softwareComponents.passwords.username"
        },
        :software_password => {
          :username        => "passwords.username"
        }
      }

      if options_hash[:hardware_type]
        unless filter_label.keys.include?(options_hash[:hardware_type])
          raise "Expected :bare_metal_instance, :hardware, :network_hardware, or :router for option :hardware_type in #{__method__}"
        end
      end

      option_to_filter_path[:hardware].keys.each do |option|
        if options_hash[option]
          hardware_object_filter.modify { |filter| filter.accept(option_to_filter_path[:hardware][option].call(options_hash[:hardware_type] || :hardware)).when_it is(options_hash[option]) }
        end
      end

      option_to_filter_path[:software].each do |option, filter_path|
        software_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option]) } if options_hash[option]
      end

      option_to_filter_path[:software_password].each do |option, filter_path|
        software_password_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option]) } if options_hash[option]
      end

      account_service = softlayer_client[:Account]
      account_service = account_service.object_filter(hardware_object_filter) unless hardware_object_filter.empty?
      account_service = account_service.object_mask("mask[id]")

      case options_hash[:hardware_type]
      when :bare_metal_instance
        hardware_data = account_service.getBareMetalInstances
      when :hardware, nil
        hardware_data = account_service.getHardware
      when :network_hardware
        hardware_data = account_service.getNetworkHardware
      when :router
        hardware_data = account_service.getRouters
      end

      software_passwords = hardware_data.collect do |hardware|
        hardware_service = softlayer_client[:Hardware].object_with_id(hardware['id'])
        hardware_service = hardware_service.object_filter(software_object_filter) unless software_object_filter.empty?
        hardware_service = hardware_service.object_mask("mask[id]")

        software_data    = hardware_service.getSoftwareComponents

        software_data.collect do |software|
          next if software.empty?

          software_service = softlayer_client[:Software_Component].object_with_id(software['id'])
          software_service = software_service.object_filter(software_password_object_filter) unless software_password_object_filter.empty?
          software_service = software_service.object_mask(SoftwarePassword.default_object_mask)
          software_service = software_service.object_mask(options_hash[:software_password_object_mask]) if options_hash[:software_password_object_mask]

          software_passwords_data = software_service.getPasswords
          software_passwords_data.map { |password| SoftwarePassword.new(softlayer_client, password) unless password.empty? }.compact
        end
      end

      software_passwords.flatten
    end

    ##
    # Retrieve a list of software  passwords from software virtual servers.
    #
    # The options parameter should contain:
    #
    # <b>+:client+</b> - The client used to connect to the API
    #
    # If no client is given, then the routine will try to use Client.default_client
    # If no client can be found the routine will raise an error.
    #
    # You may filter the list returned by adding options:
    # * <b>+:datacenter+</b>    (string/array) - Include software passwords from software on virtual servers matching this datacenter
    # * <b>+:description+</b>   (string/array) - Include software passwords from software that matches this description
    # * <b>+:domain+</b>        (string/array) - Include software passwords from software on virtual servers matching this domain
    # * <b>+:hostname+</b>      (string/array) - Include software passwords from software on virtual servers matching this hostname
    # * <b>+:manufacturer+</b>  (string/array) - Include software passwords from software that matches this manufacturer
    # * <b>+:name+</b>          (string/array) - Include software passwords from software that matches this name
    # * <b>+:username+</b>      (string/array) - Include software passwords for username matching this username
    #
    # You may use the following properties to provide virtual server or software object filter instances:
    # * <b>+:virtual_server_object_filter+</b>    (ObjectFilter) - Include software passwords from software on virtual servers that matches the criteria of this object filter
    # * <b>+:software_object_filter+</b>          (ObjectFilter) - Include software passwords from softwarethat matches the criteria of this object filter
    # * <b>+:software_password_object_filter*</b> (ObjectFilter) - Include software passwords that match the criteria of this object filter
    # * <b>+:software_password_object_mask+</b>   (string)       - Include software password properties that matches the criteria of this object mask
    #
    def self.find_passwords_for_software_on_virtual_servers(options_hash = {})
      softlayer_client = options_hash[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      if(options_hash.has_key? :virtual_server_object_filter)
        virtual_server_object_filter = options_hash[:virtual_server_object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless virtual_server_object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        virtual_server_object_filter = ObjectFilter.new()
      end

      if(options_hash.has_key? :software_object_filter)
        software_object_filter = options_hash[:software_object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless software_object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        software_object_filter = ObjectFilter.new()
      end

      if(options_hash.has_key? :software_password_object_filter)
        software_password_object_filter = options_hash[:software_password_object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless software_password_object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        software_password_object_filter = ObjectFilter.new()
      end

      option_to_filter_path = {
        :software          => {
          :description     => "softwareComponents.softwareDescription.longDescription",
          :manufacturer    => "softwareComponents.softwareDescription.manufacturer",
          :name            => "softwareComponents.softwareDescription.name",
          :username        => "softwareComponents.passwords.username"
        },
        :virtual_server    => {
          :datacenter      => "virtualGuests.datacenter.name",
          :domain          => "virtualGuests.domain",
          :hostname        => "virtualGuests.hostname",
          :tags            => "virtualGuests.tagReferences.tag.name"
        },
        :software_password => {
          :username        => "passwords.username"
        }
      }

      option_to_filter_path[:virtual_server].each do |option, filter_path|
        virtual_server_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option]) } if options_hash[option]
      end

      option_to_filter_path[:software].each do |option, filter_path|
        software_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option]) } if options_hash[option]
      end

      option_to_filter_path[:software_password].each do |option, filter_path|
        software_password_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option]) } if options_hash[option]
      end

      account_service = softlayer_client[:Account]
      account_service = account_service.object_filter(virtual_server_object_filter) unless virtual_server_object_filter.empty?
      account_service = account_service.object_mask("mask[id]")

      virtual_server_data = account_service.getVirtualGuests

      software_passwords = virtual_server_data.collect do |virtual_server|
        virtual_server_service = softlayer_client[:Virtual_Guest].object_with_id(virtual_server['id'])
        virtual_server_service = virtual_server_service.object_filter(software_object_filter) unless software_object_filter.empty?
        virtual_server_service = virtual_server_service.object_mask("mask[id]")

        software_data          = virtual_server_service.getSoftwareComponents
        software_data.collect do |software| 
          next if software.empty?

          software_service = softlayer_client[:Software_Component].object_with_id(software['id'])
          software_service = software_service.object_filter(software_password_object_filter) unless software_password_object_filter.empty?
          software_service = software_service.object_mask(SoftwarePassword.default_object_mask)
          software_service = software_service.object_mask(options_hash[:software_password_object_mask]) if options_hash[:software_password_object_mask]

          software_passwords_data = software_service.getPasswords
          software_passwords_data.map { |password| SoftwarePassword.new(softlayer_client, password) unless password.empty? }.compact
        end
      end

      software_passwords.flatten
    end

    ##
    # Update the passwords for a list of software passwords
    #
    # The options parameter should contain:
    #
    # <b>+:client+</b> - The client used to connect to the API
    #
    # If no client is given, then the routine will try to use Client.default_client
    # If no client can be found the routine will raise an error.
    #
    def self.update_passwords(passwords, password, options_hash = {})
      softlayer_client = options_hash[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      raise ArgumentError, "The new password cannot be nil"   unless password
      raise ArgumentError, "The new password cannot be empty" if password.empty?

      if ! passwords.kind_of?(Array) || ! passwords.select { |password| ! password.kind_of?(SoftLayer::SoftwarePassword) }.empty?
        raise ArgumentError, "Expected an array of SoftLayer::SoftwarePassword instances"
      end

      software_password_service = softlayer_client[:Software_Component_Password]
      software_password_service.editObjects(passwords.map { |pw| { 'id' => pw['id'], 'password' => password.to_s } })
    end

    ##
    # Returns the service for interacting with this software component password through the network API
    #
    def service
      softlayer_client[:Software_Component_Password].object_with_id(self.id)
    end

    ##
    # Make an API request to SoftLayer and return the latest properties hash
    # for this object.
    #
    def softlayer_properties(object_mask = nil)
      my_service = self.service

      if(object_mask)
        my_service = my_service.object_mask(object_mask)
      else
        my_service = my_service.object_mask(self.class.default_object_mask)
      end

      my_service.getObject()
    end

    protected

    def self.default_object_mask
      {
        "mask(SoftLayer_Software_Component_Password)" => [
                                                          'createDate',
                                                          'id',
                                                          'modifyDate',
                                                          'notes',
                                                          'password',
                                                          'port',
                                                          'username'
                                                         ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
