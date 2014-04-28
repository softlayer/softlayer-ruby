module SoftLayer
  class BareMetalServer < Server

    ##
    # Returns true if this +BareMetalServer+ is actually a Bare Metal Instance
    def bare_metal_instance?
      if @sl_hash.has_key?(:bareMetalInstanceFlag)
        self.bareMetalInstanceFlag != 0
      else
        false
      end
    end

    ##
    # Sends a ticket asking that a server be cancelled (i.e. shutdown and
    # removed from the account).
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
        # This is a bare metal instance
        softlayer_client['Billing_Item'].object_with_id(self.billingItem['id']).cancelService()
      end
    end

    ##
    # Returns the SoftLayer Service used to work with instances of this class.  For Bare Metal Servers that is +SoftLayer_Hardware+
    def service
      return softlayer_client["Hardware"]
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
    # When cancelling a server, you must provide a parameter which is the "cancellation reason".
    # The API expects very specific values for that parameter.  To simplify the API we
    # have reduced those reasons down to symbols and this method returns
    # a hash mapping from the symbol to the string that the API expects.
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
    def self.server_with_id(softlayer_client, server_id, options = {})
      if options.has_key?(:object_mask)
        object_mask = options[:object_mask]
      else
        object_mask = default_object_mask.to_sl_object_mask
      end

      required_properties_mask = ['id', 'bareMetalInstanceFlag', 'billingItem.id']

      service = softlayer_client["Hardware"]
      service = service.object_mask([object_mask, required_properties_mask])

      server_data = service.object_with_id(server_id).getObject()

      return BareMetalServer.new(softlayer_client, server_data)
    end

    ##
    # Retrieve a list of Hardware, or "bare metal" servers from the account.
    #
    # You may filter the list returned by adding options:
    #
    # * <b>+:tags+</b> (array) - an array of strings representing tags to search for on the instances
    # * <b>+:cpus+</b> (int) - return servers with the given number of (virtual) CPUs
    # * <b>+:memory+</b> (int) - return servers with at least the given amount of memory (in Gigabytes)
    # * <b>+:hostname+</b> (string) - return servers whose hostnames match the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:domain+</b> (string) - filter servers to those whose domain matches the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:datacenter+</b> (string) - find servers whose data center name matches the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:nic_speed+</b> (int) - include servers with the given nic speed (in MBPS)
    # * <b>+:public_ip+</b> (string) - return servers whose public IP address matches the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:private_ip+</b> (string) - same as :public_ip, but for private IP addresses
    #
    # Additionally you may provide options related to the request itself:
    #
    # * <b>+:object_mask+</b> (string, hash, or array) - The object mask of properties you wish to receive for the items returned If not provided, the result will use the default object mask
    # * <b>+:result_limit+</b> (hash with :limit, and :offset keys) - Limit the scope of results returned.
    #
    def self.find_servers(softlayer_client, options_hash = {})
      if(!options_hash.has_key? :object_mask)
        object_mask = BareMetalServer.default_object_mask.to_sl_object_mask
      else
        object_mask = options_hash[:object_mask]
      end

      object_filter = {}

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

      required_properties_mask = "mask[id,bareMetalInstanceFlag,billingItem.id]"

      service = softlayer_client['Account']
      service = service.object_mask(object_mask, required_properties_mask)
      service = service.object_filter(object_filter) if object_filter && !object_filter.empty?

      if options_hash.has_key?(:result_limit)
        offset = options[:result_limit][:offset]
        limit = options[:result_limit][:limit]

        service = service.result_limit(offset, limit)
      end

      bare_metal_data = service.getHardware()
      bare_metal_data.collect { |server_data| BareMetalServer.new(softlayer_client, server_data) }
    end
  end #BareMetalServer
end