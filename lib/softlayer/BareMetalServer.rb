module SoftLayer
  class BareMetalServer < Server

    def service
      return softlayer_client["Hardware"]
    end

    def self.default_object_mask
      sub_mask = ObjectMaskProperty.new("mask")
      sub_mask.type = "SoftLayer_Hardware_Server"
      sub_mask.subproperties = [
        'provisionDate',
        'hardwareStatus',
        'memoryCapacity',
        'processorPhysicalCoreAmount',
        'networkManagementIpAddress',
        'networkComponents[id, status, speed, maxSpeed, name, ipmiMacAddress, ipmiIpAddress, macAddress, primaryIpAddress, port, primarySubnet]',
        'activeTransaction[id, transactionStatus[friendlyName,name]]',
        'hardwareChassis[id,name]']
      super + [sub_mask]
    end

    ##
    # Retrive the bare metal server with the given server ID from the
    # SoftLayer API
    def self.server_with_id!(softlayer_client, server_id, options = {})
      if options.has_key?(:object_mask)
        object_mask = options[:object_mask]
      else
        object_mask = default_object_mask()
      end

      server_data = softlayer_client["Hardware"].object_with_id(server_id).object_mask(object_mask).getObject()

      return BareMetalServer.new(softlayer_client, server_data)
    end

    ##
    # retrieve a list of Hardware, or "bare metal" servers from the account
    # You may filter the list returned by adding options:
    # * :tags (array) - an array of strings representing tags to search for on the instances
    #   :cpus (int) - return servers with the given number of (virtual) CPUs
    #   :memory (int) - return servers with at least the given amount of memory (in Gigabytes)
    #   :hostname (string) - return servers whose hostnames match the query string given (see ObjectFilter::query_to_filter_operation)
    #   :domain (string) - filter servers to those whose domain matches the query string given (see ObjectFilter::query_to_filter_operation)
    #   :datacenter (string) - find servers whose data center name matches the query string given (see ObjectFilter::query_to_filter_operation)
    #   :nic_speed (int) - include servers with the given nic speed (in MBPS)
    #   :public_ip (string) - return servers whose public IP address matches the query string given (see ObjectFilter::query_to_filter_operation)
    #   :private_ip (string) - same as :public_ip, but for private IP addresses
    #
    # Additionally you may provide options related to the request itself:
    # *  :object_mask (string, hash, or array) - The object mask of properties you wish to receive for the items returned If not provided, the result will use the default object mask
    #    :result_limit (hash with :limit, and :offset keys) - Limit the scope of results returned.
    def self.find_servers!(softlayer_client, options_hash = {})
      if(!options_hash.has_key? :object_mask)
        object_mask = BareMetalServer.defaultObject_mask
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

      service = softlayer_client['Account']
      service = service.object_mask(object_mask) if object_mask && !object_mask.empty?
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