#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # This struct represents the network monitor levels of a server.
  # It is roughly equivalent to SoftLayer data type
  # SoftLayer_Network_Monitor_Version1_Query_Host_Stratum
  class NetworkMonitorLevels < Struct.new(:monitor_level, :response_level)
    def initialize(monitor_levels_data)
      self.monitor_level  = monitor_levels_data['monitorLevel']
      self.response_level = monitor_levels_data['responseLevel']
    end
  end

  ##
  # This struct represents a network monitor query result that shows the last
  # state of the network monitor
  class NetworkMonitorQueryResult < Struct.new(:finished_at, :responded_in, :response_status)
    ##
    # This constant is a mapping of network monitor query result statuses to descriptions
    STATUS_DESCRIPTIONS = {
      0 => "Down/Critical: Server is down and/or has passed the critical response threshold (extremely long ping response, abnormal behavior, etc.).",
      1 => "Warning - Server may be recovering from a previous down state, or may have taken too long to respond.",
      2 => "Up",
      3 => "Not used",
      4 => "Unknown - An unknown error has occurred. If the problem persists, contact support.",
      5 => "Unknown - An unknown error has occurred. If the problem persists, contact support."
    }

    def initialize(query_result_data)
      self.finished_at     = query_result_data['finishTime']
      self.responded_in    = query_result_data['responseTime']
      self.response_status = query_result_data['responseStatus']
    end
  end

  ##
  # This struct represents a network monitor query type used for creating
  # new network monitors.
  class NetworkMonitorQueryType < Struct.new(:argument_description, :description, :id, :monitor_level, :name)
    def initialize(query_type_data)
      self.argument_description = query_type_data['arugmentDescription']
      self.description          = query_type_data['description']
      self.id                   = query_type_data['monitorLevel']
      self.name                 = query_type_data['name']
    end
  end

  ##
  # This struct represents a network monitor response type used for configuring
  # network monitor responses when created.
  class NetworkMonitorResponseType < Struct.new(:action_description, :id, :level)
    def initialize(response_type_data)
      self.action_description = response_type_data['actionDescription']
      self.id                 = response_type_data['id']
      self.level              = response_type_data['level']
    end
  end

  ##
  # Each SoftLayer NetworkMonitor instance provides information about network
  # monitors configured to check host ping or host ports of servers.
  #
  # This class roughly corresponds to the entity SofyLayer_Network_Monitor_Version1_Query_Host
  # in the API.
  #
  class NetworkMonitor < ModelBase
    include ::SoftLayer::DynamicAttribute

    @@available_query_types    = nil
    @@available_response_types = nil

    ##
    # :attr_reader: argument_value
    # The argument to be used for this monitor, if necessary. The lowest monitoring levels (like ping)
    # ignore this setting, but higher levels like HTTP custom use it.
    sl_attr :argument_value, 'arg1Value'

    ##
    # :attr_reader: ip_address
    # The IP address to be monitored. Must be attached to the server on this object.
    sl_attr :ip_address, 'ipAddress'

    ##
    # :attr_reader:
    # The status of this monitoring instance. Anything other than "ON" means that the monitor has been disabled.
    sl_attr :status

    ##
    # :attr_reader: wait_cycles
    # The number of 5-minute cycles to wait before the "responseAction" is taken. If set to 0, the response
    # action will be taken immediately.
    sl_attr :wait_cycles, 'waitCycles'

    ##
    # The most recent result for this particular monitoring instance.
    # :call-seq:
    #   last_query_result(force_update=false)
    sl_dynamic_attr :last_query_result do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @last_query_result == nil
      end

      resource.to_update do
        NetworkMonitorQueryResult.new(self.service.object_mask("mask[finishTime,responseStatus,responseTime]").getLastResult)
      end
    end

    ##
    # The type of monitoring query that is executed when this server is monitored.
    # :call-seq:
    #   query_type(force_update=false)
    sl_dynamic_attr :query_type do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @query_type == nil
      end

      resource.to_update do
        NetworkMonitorQueryType.new(self.service.getQueryType)
      end
    end

    ##
    # The response action taken when a monitor fails.
    # :call-seq:
    #   response_type(force_update=false)
    sl_dynamic_attr :response_type do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @response_type == nil
      end

      resource.to_update do
        NetworkMonitorResponseType.new(self.service.getResponseAction)
      end
    end

    ##
    # Add a network monitor for a host ping or port check to a server.
    #
    def self.add_network_monitor(server, ip_address, query_type, response_type, wait_cycles = 0, argument_value = nil, options = {})
      softlayer_client = options[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client
      raise "#{__method__} requires a server to monitor but none was given" if !server || !server.kind_of?(Server)
      raise "#{__method__} requires an IP address to monitor but none was given" if !ip_address || ip_address.empty?
      raise "#{__method__} requires a query type for the monitor but none was given" if !query_type || !query_type.kind_of?(NetworkMonitorQueryType)
      raise "#{__method__} requires a response type for the monitor but none was given" if !response_type || !response_type.kind_of?(NetworkMonitorResponseType)

      if available_query_types(:client => softlayer_client, :query_level => server.network_monitor_levels.monitor_level).select{ |query| query.id == query_type.id }.empty?
        raise "#{__method__} requested monitor query level is not supported for this server"
      end

      if available_response_types(:client => softlayer_client, :response_level => server.network_monitor_levels.response_level).select{ |response| response.id == response_type.id }.empty?
        raise "#{__method__} requested monitor response level is not supported for this server"
      end

      network_monitor_object_filter = ObjectFilter.new()
      server_id_label               = server.kind_of?(VirtualServer) ? 'guestId' : 'hardwareId'

      network_monitor_object_filter.modify { |filter| filter.accept('networkMonitors.arg1Value').when_it          is(argument_value.to_s) }
      network_monitor_object_filter.modify { |filter| filter.accept('networkMonitors.' + server_id_label).when_it is(server.id)           }
      network_monitor_object_filter.modify { |filter| filter.accept('networkMonitors.ipAddress').when_it          is(ip_address.to_s)     }
      network_monitor_object_filter.modify { |filter| filter.accept('networkMonitors.queryTypeId').when_it        is(query_type.id)       }
      network_monitor_object_filter.modify { |filter| filter.accept('networkMonitors.responseActionId').when_it   is(response_type.id)    }
      network_monitor_object_filter.modify { |filter| filter.accept('networkMonitors.waitCycles').when_it         is(wait_cycles)         }

      if server.service.object_filter(network_monitor_object_filter).getNetworkMonitors.empty?
        network_monitor = softlayer_client[:Network_Monitor_Version1_Query_Host].createObject({
                                                                                                'arg1Value'        => argument_value.to_s,
                                                                                                server_id_label    => server.id,
                                                                                                'ipAddress'        => ip_address.to_s,
                                                                                                'queryTypeId'      => query_type.id,
                                                                                                'responseActionId' => response_type.id,
                                                                                                'waitCycles'       => wait_cycles
                                                                                              })

        NetworkMonitor.new(softlayer_client, network_monitor)
      end
    end

    ##
    # Add user customers to the list of users notified on monitor failure for the specified server. Accepts a list of  UserCustomer
    # instances or user customer usernames.
    #
    def self.add_network_monitor_notification_users(server, user_customers, options = {})
      softlayer_client = options[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client
      raise "#{__method__} requires a server to monitor but none was given" if !server || !server.kind_of?(Server)
      raise "#{__method__} requires a list user customers but none was given" if !user_customers || user_customers.empty?

      user_customers_data = user_customers.map do |user_customer|
        raise "#{__method__} requires a user customer but none was given" if !user_customer || (!user_customer.class.method_defined?(:username) && user_customer.empty?)

        user_customer_data = user_customer.class.method_defined?(:username) ? user_customer : UserCustomer.user_customer_with_username(user_customer, softlayer_client)

        raise "#{__method__} user customer with username #{user_customer.inspect} not found" unless user_customer_data

        user_customer_data
      end

      current_user_customers = server.notified_network_monitor_users.map { |notified_network_monitor_user| notified_network_monitor_user['id'] }

      user_customers_data.delete_if { |user_customer| current_user_customers.include?(user_customer['id']) }

      unless user_customers_data.empty?
        notification_monitor_user_service = server.kind_of?(VirtualServer) ? :User_Customer_Notification_Virtual_Guest : :User_Customer_Notification_Hardware
        server_id_label                   = server.kind_of?(VirtualServer) ? 'guestId' : 'hardwareId'

        user_customer_notifications = user_customers_data.map { |user_customer| { server_id_label => server.id, 'userId' => user_customer['id'] } }

        softlayer_client[notification_monitor_user_service].createObjects(user_customer_notifications)
      end
    end

    ##
    # Return the list of available query types (optionally limited to a max query level)
    #
    def self.available_query_types(options = {})
      softlayer_client = options[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      unless @@available_query_types
        available_query_types_data = softlayer_client[:Network_Monitor_Version1_Query_Host_Stratum].getAllQueryTypes
        @@available_query_types    = available_query_types_data.map{ |query_type| NetworkMonitorQueryType.new(query_type) }
      end

      if options[:query_level]
        @@available_query_types.select { |query_type| query_type.monitor_level.to_i <= options[:query_level].to_i }
      else
        @@available_query_types
      end
    end

    ##
    # Return the list of available response types (optionally limited to a max response level)
    #
    def self.available_response_types(options = {})
      softlayer_client = options[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      unless @@available_response_types
        available_response_types_data = softlayer_client[:Network_Monitor_Version1_Query_Host_Stratum].getAllResponseTypes
        @@available_response_types    = available_response_types_data.map { |response_type| NetworkMonitorResponseType.new(response_type) }
      end

      if options[:response_level]
        @@available_response_types.select { |response_type| response_type.level.to_i <= options[:response_level].to_i }
      else
        @@available_response_types
      end
    end

    ##
    # Rmove user customers from the list of users notified on monitor failure for the specified server. Accepts a list of UserCustomer
    # instances or user customer usernames.
    #
    def self.remove_network_monitor_notification_users(server, user_customers, options = {})
      softlayer_client = options[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client
      raise "#{__method__} requires a server to monitor but none was given" if !server || !server.kind_of?(Server)
      raise "#{__method__} requires a list user customers but none was given" if !user_customers || user_customers.empty?

      user_customers_data = user_customers.map do |user_customer|
        raise "#{__method__} requires a user customer but none was given" if !user_customer || (!user_customer.kind_of?(UserCustomer) && user_customer.empty?)

        user_customer_data = user_customer.kind_of?(UserCustomer) ? user_customer : UserCustomer.user_customer_with_username(user_customer, softlayer_client)

        raise "#{__method__} user customer with username #{user_customer.inspect} not found" unless user_customer_data

        user_customer_data
      end

      current_user_customers                  = user_customers_data.map { |user_customer| user_customer['id'] }
      monitor_user_notification_object_filter = ObjectFilter.new()

      monitor_user_notification_object_filter.modify { |filter| filter.accept('monitoringUserNotification.userId').when_it is(current_user_customers) }

      monitor_user_notification_data = server.service.object_filter(monitor_user_notification_object_filter).object_mask("mask[id]").getMonitoringUserNotification

      unless monitor_user_notification_data.empty?
        notification_monitor_user_service = server.kind_of?(VirtualServer) ? :User_Customer_Notification_Virtual_Guest : :User_Customer_Notification_Hardware

        softlayer_client[notification_monitor_user_service].deleteObjects(monitor_user_notification_data)
      end
    end

    ##
    # Removes the list of network monitors from their associated servers. Accpets a list of NetworkMonitor instances or id's.
    #
    def self.remove_network_monitors(network_monitors, options = {})
      softlayer_client = options[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      network_monitors_data = network_monitors.map do |network_monitor|
        raise "#{__method__} requires a network monitor instance or id but non provided" if !network_monitor || (!network_monitor.kind_of?(NetworkMonitor) && network_monitor.empty?)

        network_monitor.kind_of?(NetworkMonitor) ? { 'id' => network_monitor['id'] } : { 'id' => network_monitor }
      end

      softlayer_client[:Network_Monitor_Version1_Query_Host].deleteObjects(network_monitors_data)
    end

    ##
    # Returns the service for interacting with this network monitor component through the network API
    #
    def service
      softlayer_client[:Network_Monitor_Version1_Query_Host].object_with_id(self.id)
    end

    protected

    def self.default_object_mask
      {
        "mask(SoftLayer_Network_Monitor_Version1_Query_Host)" => [
                                                                  'arg1Value',
                                                                  'guestId',
                                                                  'hardwareId',
                                                                  'hostId',
                                                                  'id',
                                                                  'ipAddress',
                                                                  'status',
                                                                  'waitCycles'
                                                                 ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
