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
    # :attr_reader:
    # The date this username/password pair was created.
    sl_attr :created, 'createDate'

    ##
    # :attr_reader:
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
    # * <b>+:datacenter+</b>    (string) - Include software passwords from application delivery controllers matching this datacenter
    # * <b>+:name+</b>          (string) - Include software passwords from application delivery controllers that matches this name
    # * <b>+:tags+</b>          (Array)  - Include software passwords from application delivery controllers that matches these tags
    # * <b>+:username+</b>      (string) - Include software passwords that match this username
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
        :advanced_mode     => "applicationDeliveryControllers.advancedModeFlag",
        :datacenter        => "applicationDeliveryControllers.datacenter.name",
        :name              => "applicationDeliveryControllers.name",
        :tags              => "applicationDeliveryControllers.tagReferences.tag.name",
        :software_password => {
          :username        => "password.username"
        }
      }

      application_delivery_controller_object_filter.modify { |filter| filter.accept(option_to_filter_path[:advanced_mode]).when_it is(true) }

      [ :datacenter, :name ].each do |option|
        if options_hash[option]
          application_delivery_controller_object_filter.modify { |filter| filter.accept(option_to_filter_path[option]).when_it is(options_hash[option]) }
        end
      end

      if options_hash[:tags]
        application_delivery_controller_object_filter.set_criteria_for_key_path(option_to_filter_path[:tags],
                                                                                {
                                                                                  'operation' => 'in',
                                                                                  'options' => [{
                                                                                                  'name' => 'data',
                                                                                                  'value' => options_hash[:tags].collect{ |tag_value| tag_value.to_s }
                                                                                                }]
                                                                                })
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
    # * <b>+:datacenter+</b>    (string) - Include software passwords from vlan firewalls matching this datacenter
    # * <b>+:vlan_name+</b>     (Array)  - Include software passwords from vlans that matches these names
    # * <b>+:vlan_numbers+</b>  (Array)  - Include software passwords from vlans that matches these numbers
    # * <b>+:vlan_space+</b>    (symbol) - Include software passwords from vlans that match this space
    # * <b>+:vlan_tags+</b>     (Array)  - Include software passwords from vlans that matches these tags
    # * <b>+:vlan_fw_fqdn+</b>  (string) - Include software passwords from vlan firewalls that match this fqdn
    # * <b>+:vlan_fw_tags+</b>  (Array)  - Include software passwords from vlan firewalls that matches these tags
    # * <b>+:vlan_fw_type+</b>  (string) - Include software passwords from vlan firewalls that match this type
    # * <b>+:username+</b>      (string) - Include software passwords that match this username
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
        :vlan_dedicated_fw => lambda { |vlan_space| return [ filter_label[vlan_space], '.', 'dedicatedFirewallFlag' ].join  },
        :vlan_names        => lambda { |vlan_space| return [ filter_label[vlan_space], '.', 'name' ].join                   },
        :vlan_numbers      => lambda { |vlan_space| return [ filter_label[vlan_space], '.', 'vlanNumber' ].join             },
        :vlan_tags         => lambda { |vlan_space| return [ filter_label[vlan_space], '.', 'tagReferences.tag.name' ].join },
        :vlan_firewall     => {
          :vlan_fw_datacenter => "networkVlanFirewall.datacenter.name",
          :vlan_fw_fqdn       => "networkVlanFirewall.fullyQualifiedDomainName",
          :vlan_fw_type       => "networkVlanFirewall.firewallType"
        },
        :vlan_fw_tags      => "networkVlanFirewall.tagReferences.tag.name"
      }

      if options_hash[:vlan_space] && ! filter_label.keys.include?(options_hash[:vlan_space])
        raise "Expected one of :all, :private, or :public for option :vlan_space in #{__method__}"
      end

      option_to_filter_path[:software_password].each do |option, filter_path|
        software_password_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option]) } if options_hash[option]
      end

      vlan_space = options_hash[:vlan_space] || :all

      vlan_object_filter.modify { |filter| filter.accept(option_to_filter_path[:vlan_dedicated_fw].call(vlan_space)).when_it is(1) }
      vlan_object_filter.modify { |filter| filter.accept(option_to_filter_path[:vlan_name].call(vlan_space)).when_it is(options_hash[:vlan_name]) } if options_hash[:vlan_name]

      [ :vlan_names, :vlan_numbers, :vlan_tags ].each do |option|
        if options_hash[option]
          vlan_object_filter.set_criteria_for_key_path(option_to_filter_path[option].call(vlan_space),
                                                       {
                                                         'operation' => 'in',
                                                         'options' => [{
                                                                         'name' => 'data',
                                                                         'value' => options_hash[option].collect{ |tag_value| tag_value.to_s }
                                                                       }]
                                                     })
        end
      end

      option_to_filter_path[:vlan_firewall].each do |option, filter_path|
        vlan_firewall_object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option]) } if options_hash[option]
      end

      if options_hash[:vlan_fw_tags]
        vlan_firewall_object_filter.set_criteria_for_key_path(option_to_filter_path[:vlan_fw_tags],
                                                              {
                                                                'operation' => 'in',
                                                                'options' => [{
                                                                                'name' => 'data',
                                                                                'value' => options_hash[:vlan_fw_tags].collect{ |tag_value| tag_value.to_s }
                                                                              }]
                                                              })
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
    # Returns the service for interacting with this software component passowrd through the network API
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
