#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # Each SoftLayer Software instance provides information about software
  # installed on a specific piece of hardware.
  #
  # This class roughly corresponds to the entity SoftLayer_Software_Component
  # in the API.
  #
  class Software < ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader:
    # The manufacturer code that is needed to activate a license.
    sl_attr :manufacturer_activation_code, 'manufacturerActivationCode'

    ##
    # :attr_reader:
    # A license key for this specific installation of software, if it is needed.
    sl_attr :manufacturer_license_key,     'manufacturerLicenseInstance'

    ##
    # The manufacturer, name and version of a piece of software.
    sl_dynamic_attr :description do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @description == nil
      end

      resource.to_update do
        description = self.service.getSoftwareDescription
        description['longDescription']
      end
    end

    ##
    # The name of this specific piece of software. 
    sl_dynamic_attr :name do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @name == nil
      end

      resource.to_update do
        description = self.service.getSoftwareDescription
        description['name']
      end
    end

    ##
    # Username/Password pairs used for access to this Software Installation.
    sl_dynamic_attr :passwords do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @passwords == nil
      end

      resource.to_update do
        passwords = self.service.getPasswords
        passwords.collect { |password_data| SoftwarePassword.new(softlayer_client, password_data) }
      end
    end

    ##
    # Adds specified username/password combination to current software instance
    #
    def add_user_password(username, password, options = {})
      raise ArgumentError, "The new password cannot be nil"   unless password
      raise ArgumentError, "The new username cannot be nil"   unless username
      raise ArgumentError, "The new password cannot be empty" if password.empty?
      raise ArgumentError, "The new username cannot be empty" if username.empty?

      raise Exception, "Cannot add username password, a Software Password already exists for the provided username" if self.has_user_password?(username.to_s)

      add_user_pw_template = {
        'softwareId' => self['id'].to_i,
        'password'   => password.to_s,
        'username'   => username.to_s
      }

      add_user_pw_template['notes'] = options['notes'].to_s if options.has_key?('notes')
      add_user_pw_template['port']  = options['port'].to_i  if options.has_key?('port')

      softlayer_client[:Software_Component_Password].createObject(add_user_pw_template)

      @passwords = nil
    end

    ##
    # Deletes specified username password from current software instance
    #
    #
    # This is a final action and cannot be undone.
    # the transaction will proceed immediately.
    #
    # Call it with extreme care!
    def delete_user_password!(username)
      user_password = self.passwords.select { |sw_pw| sw_pw.username == username.to_s }

      unless user_password.empty?
        softlayer_client[:Software_Component_Password].object_with_id(user_password.first['id']).deleteObject
        @passwords = nil
      end
    end

    ##
    # Returns whether or not one of the Software Passowrd instances pertains to the specified user
    #
    def has_user_password?(username)
      self.passwords.map { |sw_pw| sw_pw.username }.include?(username)
    end

    ##
    # Retrieve a list of software from hardware devices.
    #
    # The options parameter should contain:
    #
    # <b>+:client+</b> - The client used to connect to the API
    #
    # If no client is given, then the routine will try to use Client.default_client
    # If no client can be found the routine will raise an error.
    #
    # You may filter the list returned by adding options:
    # * <b>+:datacenter+</b>    (string) - Include software from hardware matching this datacenter
    # * <b>+:description+</b>   (string) - Include software that matches this description
    # * <b>+:domain+</b>        (string) - Include software from hardware matching this domain
    # * <b>+:hardware_type+</b> (string) - Include software from hardware matching this hardware type
    # * <b>+:hostname+</b>      (string) - Include software from hardware matching this hostname
    # * <b>+:manufacturer+</b>  (string) - Include software that matches this manufacturer
    # * <b>+:name+</b>          (string) - Include software that matches this name
    # * <b>+:username+</b>      (string) - Include software that has software password matching this username
    #
    # You may use the following properties to provide hardware or software object filter instances:
    # * <b>+:hardware_object_filter+</b> (ObjectFilter) - Include software from hardware that matches the criteria of this object filter
    # * <b>+:software_object_filter+</b> (ObjectFilter) - Include software that matches the criteria of this object filter
    # * <b>+:software_object_mask+</b>   (string)       - Include software properties that matches the criteria of this object mask
    #
    def self.find_software_on_hardware(options_hash = {})
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

      filter_label = {
        :bare_metal_instance => "bareMetalInstances",
        :hardware            => "hardware",
        :network_hardware    => "networkHardware",
        :router              => "routers"
      }

      option_to_filter_path = {
        :datacenter     => lambda { |hardware_type| return [ filter_label[hardware_type], '.datacenter.name' ].join        },
        :domain         => lambda { |hardware_type| return [ filter_label[hardware_type], '.domain' ].join                 },
        :hostname       => lambda { |hardware_type| return [ filter_label[hardware_type], '.hostname' ].join               },
        :tags           => lambda { |hardware_type| return [ filter_label[hardware_type], '.tagReferences.tag.name' ].join },
        :software       => {
          :description  => "softwareComponents.softwareDescription.longDescription",
          :manufacturer => "softwareComponents.softwareDescription.manufacturer",
          :name         => "softwareComponents.softwareDescription.name",
          :username     => "softwareComponents.passwords.username"
        }
      }

      if options_hash[:hardware_type]
        unless filter_label.keys.include?(options_hash[:hardware_type])
          raise "Expected :bare_metal_instance, :hardware, :network_hardware, or :router for option :hardware_type in #{__method__}"
        end
      end

      [ :datacenter, :domain, :hostname ].each do |option|
        if options_hash[option]
          hardware_object_filter.modify { |filter| filter.accept(option_to_filter_path[option].call(options_hash[:hardware_type] || :hardware)).when_it is(options_hash[option]) }
        end
      end

      if options_hash[:tags]
        hardware_object_filter.set_criteria_for_key_path(option_to_filter_path[:tags].call(options_hash[:hardware_type] || :hardware),
                                                         {
                                                           'operation' => 'in',
                                                           'options' => [{
                                                                           'name' => 'data',
                                                                           'value' => options_hash[:tags].collect{ |tag_value| tag_value.to_s }
                                                                         }]
                                                         })
      end

      option_to_filter_path[:software].each do |option, filter_path|
        software_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option]) } if options_hash[option]
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

      software = hardware_data.collect do |hardware|
        hardware_service = softlayer_client[:Hardware].object_with_id(hardware['id'])
        hardware_service = hardware_service.object_filter(software_object_filter) unless software_object_filter.empty?
        hardware_service = hardware_service.object_mask(Software.default_object_mask)
        hardware_service = hardware_service.object_mask(options_hash[:software_object_mask]) if options_hash[:software_object_mask]

        software_data = hardware_service.getSoftwareComponents
        software_data.map { |software| Software.new(softlayer_client, software) unless software.empty? }.compact
      end

      software.flatten
    end

    ##
    # Retrieve a list of software from virtual servers.
    #
    # The options parameter should contain:
    #
    # <b>+:client+</b> - The client used to connect to the API
    #
    # If no client is given, then the routine will try to use Client.default_client
    # If no client can be found the routine will raise an error.
    #
    # You may filter the list returned by adding options:
    # * <b>+:datacenter+</b>    (string) - Include software from virtual servers matching this datacenter
    # * <b>+:description+</b>   (string) - Include software that matches this description
    # * <b>+:domain+</b>        (string) - Include software from virtual servers matching this domain
    # * <b>+:hostname+</b>      (string) - Include software from virtual servers matching this hostname
    # * <b>+:manufacturer+</b>  (string) - Include software that matches this manufacturer
    # * <b>+:name+</b>          (string) - Include software that matches this name
    # * <b>+:username+</b>      (string) - Include software that has software password matching this username
    #
    # You may use the following properties to provide virtual server or software object filter instances:
    # * <b>+:virtual_server_object_filter+</b> (ObjectFilter) - Include software from virtual servers that matches the criteria of this object filter
    # * <b>+:software_object_filter+</b>       (ObjectFilter) - Include software that matches the criteria of this object filter
    # * <b>+:software_object_mask+</b>         (string)       - Include software properties that matches the criteria of this object mask
    #
    def self.find_software_on_virtual_servers(options_hash = {})
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

      option_to_filter_path = {
        :software       => {
          :description  => "softwareComponents.softwareDescription.longDescription",
          :manufacturer => "softwareComponents.softwareDescription.manufacturer",
          :name         => "softwareComponents.softwareDescription.name",
          :username     => "softwareComponents.passwords.username"
        },
        :virtual_server => {
          :datacenter   => "virtualGuests.datacenter.name",
          :domain       => "virtualGuests.domain",
          :hostname     => "virtualGuests.hostname",
          :tags         => "virtualGuests.tagReferences.tag.name"
        }
      }

      if options_hash[:tags]
        virtual_server_object_filter.set_criteria_for_key_path(option_to_filter_path[:virtual_server][:tags],
                                                               {
                                                                 'operation' => 'in',
                                                                 'options' => [{
                                                                                 'name' => 'data',
                                                                                 'value' => options_hash[:tags].collect{ |tag_value| tag_value.to_s }
                                                                               }]
                                                               })
      end

      option_to_filter_path[:virtual_server].each do |option, filter_path|
        next if option == :tags
        virtual_server_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option]) } if options_hash[option]
      end

      option_to_filter_path[:software].each do |option, filter_path|
        software_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option]) } if options_hash[option]
      end

      account_service = softlayer_client[:Account]
      account_service = account_service.object_filter(virtual_server_object_filter) unless virtual_server_object_filter.empty?
      account_service = account_service.object_mask("mask[id]")

      virtual_server_data = account_service.getVirtualGuests

      software = virtual_server_data.collect do |virtual_server|
        virtual_server_service = softlayer_client[:Virtual_Guest].object_with_id(virtual_server['id'])
        virtual_server_service = virtual_server_service.object_filter(software_object_filter) unless software_object_filter.empty?
        virtual_server_service = virtual_server_service.object_mask(Software.default_object_mask)
        virtual_server_service = virtual_server_service.object_mask(options_hash[:software_object_mask]) if options_hash[:software_object_mask]

        software_data = virtual_server_service.getSoftwareComponents
        software_data.map { |software| Software.new(softlayer_client, software) unless software.empty? }.compact
      end

      software.flatten
    end

    ##
    # Returns the service for interacting with this software component through the network API
    #
    def service
      softlayer_client[:Software_Component].object_with_id(self.id)
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
        "mask(SoftLayer_Software_Component)" => [
                                                 'id',
                                                 'manufacturerActivationCode',
                                                 'manufacturerLicenseInstance'
                                                ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
