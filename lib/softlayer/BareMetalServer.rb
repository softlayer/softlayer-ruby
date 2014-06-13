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
  # This class represents a Bare Metal Server, a hardware server in contrast to a virtual machine,
  # in the SoftLayer Environment. It corresponds rougly to the +SoftLayer_Hardware+ and
  # +SoftLayer_Hardware_Server+ services in the SoftLayer API
  #
  # http://sldn.softlayer.com/reference/datatypes/SoftLayer_Hardware
  # http://sldn.softlayer.com/reference/datatypes/SoftLayer_Hardware_Server
  #
  class BareMetalServer < Server

    ##
    # Returns true if this +BareMetalServer+ is actually a Bare Metal Instance
    # a Bare Metal Instance is physical, hardware server that is is provisioned to
    # match a profile with characteristics similar to a Virtual Server
    #
    # This is an important distincition in rare cases, like cancelling the server.
    #
    def bare_metal_instance?
      if has_sl_property?(:bareMetalInstanceFlag)
        self["bareMetalInstanceFlag"] != 0
      else
        false
      end
    end

    ##
    # Sends a ticket asking that a server be cancelled (i.e. shutdown and
    # removed from the account).
    #
    # The +cancellation_reason+ parameter should be a key from the hash returned
    # by +BareMetalServer::cancellation_reasons+.
    #
    # You may add your own, more specific reasons for cancelling a server in the
    # +comments+ parameter.
    #
    def cancel!(reason = :unneeded, comment = '')
      if !bare_metal_instance? then
        cancellation_reasons = self.class.cancellation_reasons()
        cancel_reason = cancellation_reasons[reason] || cancellation_reasons[:unneeded]
        softlayer_client["Ticket"].createCancelServerTicket(self.id, cancel_reason, comment, true, 'HARDWARE')
      else
        # Note that reason and comment are ignored in this case, unfortunately
        softlayer_client['Billing_Item'].object_with_id(self.billingItem['id'].to_i).cancelService()
      end
    end

    ##
    # Returns the SoftLayer Service used to work with this Server
    # For Bare Metal Servers that is +SoftLayer_Hardware+ though in some special cases
    # you may have to use +SoftLayer_Hardware_Server+ as a type or service.
    def service
      return softlayer_client["Hardware"].object_with_id(self.id)
    end

    ##
    # Returns the default object mask used when fetching servers from the API when an
    # explicit object mask is not provided.
    def self.default_object_mask
      sub_mask = {
        "mask(SoftLayer_Hardware_Server)" => [
          'bareMetalInstanceFlag',
          'provisionDate',
          'hardwareStatus',
          'memoryCapacity',
          'processorPhysicalCoreAmount',
          'networkManagementIpAddress',
          'networkComponents[id, status, speed, maxSpeed, name, ipmiMacAddress, ipmiIpAddress, macAddress, primaryIpAddress, port, primarySubnet]',
          'activeTransaction[id, transactionStatus[friendlyName,name]]',
          'hardwareChassis[id, name]'
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
    # Retrive the bare metal server with the given server ID from the
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

      hardware_service = softlayer_client["Hardware"]
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
    # * <b>+:tags+</b> (array) - an array of strings representing tags to search for on the instances
    # * <b>+:cpus+</b> (int) - return servers with the given number of (virtual) CPUs
    # * <b>+:memory+</b> (int) - return servers with at least the given amount of memory (in Gigabytes)
    # * <b>+:hostname+</b> (string) - return servers whose hostnames match the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:domain+</b> (string) - filter servers to those whose domain matches the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:datacenter+</b> (string) - find servers whose data center name matches the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:nic_speed+</b> (int) - include servers with the given nic speed (in Mbps)
    # * <b>+:public_ip+</b> (string) - return servers whose public IP address matches the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:private_ip+</b> (string) - same as :public_ip, but for private IP addresses
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
      else
        object_filter = {}
      end

      option_to_filter_path = {
        :cpus => "hardware.processorPhysicalCoreAmount",
        :memory => "hardware.memoryCapacity",
        :hostname => "hardware.hostname",
        :domain => "hardware.domain",
        :datacenter => "hardware.datacenter.name",
        :nic_speed => "hardware.networkComponents.maxSpeed",
        :public_ip => "hardware.primaryIpAddress",
        :private_ip => "hardware.primaryBackendIpAddress"
      }

      # For each of the options in the option_to_filter_path map, if the options hash includes
      # that particular option, add a clause to the object filter that filters for the matching
      # value
      option_to_filter_path.each do |option, filter_path|
        object_filter.merge!(SoftLayer::ObjectFilter.build(filter_path, options_hash[option])) if options_hash.has_key?(option)
      end

      # Tags get a much more complex object filter operation so we handle them separately
      if options_hash.has_key?(:tags)
        object_filter.merge!(SoftLayer::ObjectFilter.build("hardware.tagReferences.tag.name", {
          'operation' => 'in',
          'options' => [{
            'name' => 'data',
            'value' => options_hash[:tags]
            }]
          } ));
      end

      account_service = softlayer_client['Account']
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