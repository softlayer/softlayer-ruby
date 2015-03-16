#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # Each SoftLayer NetworkMonitor instance provides information about network
  # monitors configured to check host ping or host ports of servers.
  #
  # This class roughly corresponds to the entity SofyLayer_Network_Monitor_Version1_Query_Host
  # in the API.
  #
  class NetworkMonitor < ModelBase
    include ::SoftLayer::DynamicAttribute

    @@query_result_descriptions = {
      0 => "Down/Critical: Server is down and/or has passed the critical response threshold (extremely long ping response, abnormal behavior, etc.).",
      1 => "Warning - Server may be recovering from a previous down state, or may have taken too long to respond.",
      2 => "Up",
      3 => "Not used",
      4 => "Unknown - An unknown error has occurred. If the problem persists, contact support.",
      5 => "Unknown - An unknown error has occurred. If the problem persists, contact support."
    }

    ##
    # :attr_reader:
    # The argument to be used for this monitor, if necessary. The lowest monitoring levels (like ping)
    # ignore this setting, but higher levels like HTTP custom use it.
    sl_attr :argument_value, 'arg1Value'

    ##
    # :attr_reader:
    # The IP address to be monitored. Must be attached to the server on this object.
    sl_attr :ip_address, 'ipAddress'

    ##
    # :attr_reader:
    # The status of this monitoring instance. Anything other than "ON" means that the monitor has been disabled.
    sl_attr :status

    ##
    # :attr_reader:
    # The number of 5-minute cycles to wait before the "responseAction" is taken. If set to 0, the response
    # action will be taken immediately.
    sl_attr :wait_cycles, 'waitCycles'

    ##
    # The most recent result for this particular monitoring instance.
    sl_dynamic_attr :last_query_result do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @last_query_result == nil
      end

      resource.to_update do
        self.service.object_mask("mask[finishTime,responseStatus,responseTime]").getLastResult
      end
    end

    ##
    # The type of monitoring query that is executed when this server is monitored.
    sl_dynamic_attr :query_type do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @query_type == nil
      end

      resource.to_update do
        self.service.getQueryType
      end
    end

    ##
    # The action taken when a monitor fails.
    sl_dynamic_attr :response_action do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @response_action == nil
      end

      resource.to_update do
        self.service.getResponseAction
      end
    end

    ##
    # Return the list of descriptions by result id for last query responses.
    #
    def self.query_result_descriptions
      @@query_result_descriptions
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
