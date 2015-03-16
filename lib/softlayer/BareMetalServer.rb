#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++



module SoftLayer
  #
  # This class represents a Bare Metal Server, a hardware server in contrast to a virtual machine,
  # in the SoftLayer Environment. It corresponds roughly to the +SoftLayer_Hardware+ and
  # +SoftLayer_Hardware_Server+ services in the SoftLayer API
  #
  # http://sldn.softlayer.com/reference/datatypes/SoftLayer_Hardware
  #
  # http://sldn.softlayer.com/reference/datatypes/SoftLayer_Hardware_Server
  #
  class BareMetalServer < Server
    include ::SoftLayer::DynamicAttribute

    ##
    # A lsst of configured network monitors.
    #
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
    # Add user customers to the list of users notified on monitor failure. Accepts a list of  UserCustomer
    # instances or user customer usernames.
    #
    def add_monitor_notification_users(user_customers)
      raise "#{__method__} requires a list user customers but none was given" if !user_customers || user_customers.empty?

      user_customers_data = user_customers.map do |user_customer|
        raise "#{__method__} requires a user customer but none was given" if !user_customer || (!user_customer.class.method_defined?(:username) && user_customer.empty?)

        user_customer_data = user_customer.class.method_defined?(:username) ? user_customer : UserCustomer.user_customer_with_username(user_customer, softlayer_client)

        raise "#{__method__} user customer with username #{user_customer.inspect} not found" unless user_customer_data

        user_customer_data
      end

      current_user_customers = self.notified_monitor_users.map { |notified_monitor_user| notified_monitor_user['id'] }

      user_customers_data.delete_if { |user_customer| current_user_customers.include?(user_customer['id']) }

      unless user_customers_data.empty?
        user_customer_notifications = user_customers_data.map { |user_customer| { 'hardwareId' => self.id, 'userId' => user_customer['id'] } }

        softlayer_client[:User_Customer_Notification_Hardware].createObjects(user_customer_notifications)

        @notified_monitor_users = nil
      end
    end

    ##
    # Returns true if this +BareMetalServer+ is actually a Bare Metal Instance
    # a Bare Metal Instance is physical, hardware server that is is provisioned to
    # match a profile with characteristics similar to a Virtual Server
    #
    # This is an important distinction in rare cases, like cancelling the server.
    #
    def bare_metal_instance?
      if has_sl_property?(:bareMetalInstanceFlag)
        self['bareMetalInstanceFlag'] != 0
      else
        false
      end
    end

    ##
    # Sends a ticket asking that a server be cancelled (i.e. shutdown and
    # removed from the account).
    #
    # The +cancellation_reason+ parameter should be a key from the hash returned
    # by BareMetalServer::cancellation_reasons.
    #
    # You may add your own, more specific reasons for cancelling a server in the
    # +comments+ parameter.
    #
    def cancel!(reason = :unneeded, comment = '')
      if !bare_metal_instance? then
        cancellation_reasons = self.class.cancellation_reasons()
        cancel_reason = cancellation_reasons[reason] || cancellation_reasons[:unneeded]
        softlayer_client[:Ticket].createCancelServerTicket(self.id, cancel_reason, comment, true, 'HARDWARE')
      else
        # Note that reason and comment are ignored in this case, unfortunately
        softlayer_client[:Billing_Item].object_with_id(self.service.object_mask("mask[id]").getBillingItem['id'].to_i).cancelService()
      end
    end

    ##
    # Returns the username/password combinations for remote management accounts
    #
    def remote_management_accounts
      self['remoteManagementAccounts']
    end

    ##
    # Rmove user customers from the list of users notified on monitor failure. Accepts a list of UserCustomer
    # instances or user customer usernames.
    #
    def remove_monitor_notification_users(user_customers)
      raise "#{__method__} requires a list user customers but none was given" if !user_customers || user_customers.empty?

      user_customers_data = user_customers.map do |user_customer|
        raise "#{__method__} requires a user customer but none was given" if !user_customer || (!user_customer.class.method_defined?(:username) && user_customer.empty?)

        user_customer_data = user_customer.class.method_defined?(:username) ? user_customer : UserCustomer.user_customer_with_username(user_customer, softlayer_client)

        raise "#{__method__} user customer with username #{user_customer.inspect} not found" unless user_customer_data

        user_customer_data
      end

      current_user_customers = user_customers_data.map { |user_customer| user_customer['id'] }

      monitor_user_notification_object_filter = ObjectFilter.new()

      monitor_user_notification_object_filter.set_criteria_for_key_path('monitoringUserNotification.userId',
                                                                        {
                                                                          'operation' => 'in',
                                                                          'options' => [{
                                                                                          'name' => 'data',
                                                                                          'value' => current_user_customers.map{ |uid| uid.to_s }
                                                                                        }]
                                                                        })

      monitor_user_notification_data = self.service.object_filter(monitor_user_notification_object_filter).object_mask("mask[id]").getMonitoringUserNotification

      unless monitor_user_notification_data.empty?
        softlayer_client[:User_Customer_Notification_Hardware].deleteObjects(monitor_user_notification_data)

        @notified_monitor_users = nil
      end
    end

    ##
    # Returns the typical Service used to work with this Server
    # For Bare Metal Servers that is +SoftLayer_Hardware+ though in some special cases
    # you may have to use +SoftLayer_Hardware_Server+ as a type or service.  That
    # service object is available through the hardware_server_service method
    def service
      return softlayer_client[:Hardware_Server].object_with_id(self.id)
    end

    ##
    # Returns the default object mask used when fetching servers from the API when an
    # explicit object mask is not provided.
    def self.default_object_mask
      sub_mask = {
        "mask(SoftLayer_Hardware_Server)" => [
                                              'activeTransaction[id, transactionStatus[friendlyName,name]]',
                                              'bareMetalInstanceFlag',
                                              'hardwareChassis[id, name]',
                                              'hardwareStatus',
                                              'memoryCapacity',
                                              'networkComponents[id, maxSpeed, name, ipmiIpAddress, ipmiMacAddress, macAddress, port, primaryIpAddress, primarySubnet, speed, status]',
                                              'networkManagementIpAddress',
                                              'processorPhysicalCoreAmount',
                                              'provisionDate',
                                              'remoteManagementAccounts[password,username]'
                                             ]
      }

      super.merge(sub_mask)
    end

    ##
    # Returns a list of the cancellation reasons to use when cancelling a server.
    #
    # When cancelling a server with the cancel! method, the first parameter is the reason and
    # should be one of the keys in the hash returned by this method.  This, in turn
    # will be translated into a string which is, for all intents and purposes, a
    # literal string constant with special meaning to the SoftLayer API.
    #
    def self.cancellation_reasons
      {
        :unneeded => 'No longer needed',
        :closing => 'Business closing down',
        :cost => 'Server / Upgrade Costs',
        :migrate_larger => 'Migrating to larger server',
        :migrate_smaller => 'Migrating to smaller server',
        :datacenter => 'Migrating to a different SoftLayer datacenter',
        :performance => 'Network performance / latency',
        :support => 'Support response / timing',
        :sales => 'Sales process / upgrades',
        :moving => 'Moving to competitor',
      }
    end

    ##
    # Returns the max port speed of the public network interfaces of the server taking into account
    # bound interface pairs (redundant network cards).
    def firewall_port_speed
      network_components = self.service.object_mask("mask[id,maxSpeed,networkComponentGroup.networkComponents]").getFrontendNetworkComponents()

      # Split the interfaces into grouped and ungrouped interfaces. The max speed of a group will be the sum
      # of the individual speeds in that group.  The max speed of ungrouped interfaces is simply the max speed
      # of that interface.
      grouped_interfaces, ungrouped_interfaces = network_components.partition{ |interface| interface.has_key?("networkComponentGroup") }

      if !grouped_interfaces.empty?
        group_speeds = grouped_interfaces.collect do |interface|
          interface['networkComponentGroup']['networkComponents'].inject(0) {|total_speed, component| total_speed += component['maxSpeed']}
        end

        max_group_speed = group_speeds.max
      else
        max_group_speed = 0
      end

      if !ungrouped_interfaces.empty?
        max_ungrouped_speed = ungrouped_interfaces.collect { |interface| interface['maxSpeed']}.max
      else
        max_ungrouped_speed = 0
      end

      return [max_group_speed, max_ungrouped_speed].max
    end

    ##
    # Retrieve the bare metal server with the given server ID from the
    # SoftLayer API
    #
    # The options parameter should contain:
    #
    # <b>+:client+</b> - The client used to connect to the API
    #
    # If no client is given, then the routine will try to use Client.default_client
    # If no client can be found the routine will raise an error.
    def self.server_with_id(server_id, options = {})
      softlayer_client = options[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      hardware_service = softlayer_client[:Hardware_Server]
      hardware_service = hardware_service.object_mask(default_object_mask.to_sl_object_mask)

      if options.has_key?(:object_mask)
        object_mask = hardware_service.object_mask(options[:object_mask])
      end

      server_data = hardware_service.object_with_id(server_id).getObject()

      return BareMetalServer.new(softlayer_client, server_data)
    end

    ##
    # Retrieve a list of Bare Metal servers from the account
    #
    # The options parameter should contain:
    #
    # <b>+:client+</b> - The client used to connect to the API
    #
    # If no client is given, then the routine will try to use Client.default_client
    # If no client can be found the routine will raise an error.
    #
    # You may filter the list returned by adding options:
    #
    # * <b>+:tags+</b>       (string/array) - an array of strings representing tags to search for on the instances
    # * <b>+:cpus+</b>       (int/array)    - return servers with the given number of (virtual) CPUs
    # * <b>+:memory+</b>     (int/array)    - return servers with at least the given amount of memory (in Gigabytes)
    # * <b>+:hostname+</b>   (string/array) - return servers whose hostnames match the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:domain+</b>     (string/array) - filter servers to those whose domain matches the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:datacenter+</b> (string/array) - find servers whose data center name matches the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:nic_speed+</b>  (int/array)    - include servers with the given nic speed (in Mbps)
    # * <b>+:public_ip+</b>  (string/array) - return servers whose public IP address matches the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:private_ip+</b> (string/array) - same as :public_ip, but for private IP addresses
    #
    # Additionally you may provide options related to the request itself:
    #
    # * <b>+:object_mask+</b> (string, hash, or array) - The object mask of properties you wish to receive for the items returned If not provided, the result will use the default object mask
    # * <b>+:result_limit+</b> (hash with :limit, and :offset keys) - Limit the scope of results returned.
    #
    def self.find_servers(options_hash = {})
      softlayer_client = options_hash[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      if(options_hash.has_key? :object_filter)
        object_filter = options_hash[:object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        object_filter = ObjectFilter.new()
      end

      option_to_filter_path = {
        :cpus       => "hardware.processorPhysicalCoreAmount",
        :memory     => "hardware.memoryCapacity",
        :hostname   => "hardware.hostname",
        :domain     => "hardware.domain",
        :datacenter => "hardware.datacenter.name",
        :nic_speed  => "hardware.networkComponents.maxSpeed",
        :public_ip  => "hardware.primaryIpAddress",
        :private_ip => "hardware.primaryBackendIpAddress",
        :tags       => "hardware.tagReferences.tag.name"
      }

      # For each of the options in the option_to_filter_path map, if the options hash includes
      # that particular option, add a clause to the object filter that filters for the matching
      # value
      option_to_filter_path.each do |option, filter_path|
        object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option])} if options_hash[option]
      end

      account_service = softlayer_client[:Account]
      account_service = account_service.object_filter(object_filter) unless object_filter.empty?
      account_service = account_service.object_mask(default_object_mask.to_sl_object_mask)

      if(options_hash.has_key? :object_mask)
        account_service = account_service.object_mask(options_hash[:object_mask])
      end

      if options_hash.has_key?(:result_limit)
        offset = options[:result_limit][:offset]
        limit = options[:result_limit][:limit]

        account_service = account_service.result_limit(offset, limit)
      end

      bare_metal_data = account_service.getHardware()
      bare_metal_data.collect { |server_data| BareMetalServer.new(softlayer_client, server_data) }
    end
  end #BareMetalServer
end
