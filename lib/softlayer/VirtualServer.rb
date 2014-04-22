module SoftLayer
  class VirtualServer < Server

    ##
    # Cancel this virtual server immediately and delete all its data.
    #
    def cancel!
      self.service.object_with_id(self.id).deleteObject()
    end
    
    ##
    # Returns the SoftLayer Service used to work with instances of this class.  For Virtual Servers that is +SoftLayer_Virtual_Guest+
    def service
      return softlayer_client["Virtual_Guest"]
    end

    ##
    # Returns the default object mask used when fetching servers from the API when an 
    # explicit object mask is not provided.
    def self.default_object_mask
      sub_mask = ObjectMaskProperty.new("mask")
      sub_mask.type = "SoftLayer_Virtual_Guest"
      sub_mask.subproperties = [
       'createDate',
       'modifyDate',
       'provisionDate',
       'dedicatedAccountHostOnlyFlag',
       'lastKnownPowerState.name',
       'powerState',
       'status',
       'maxCpu',
       'maxMemory',
       'activeTransaction[id, transactionStatus[friendlyName,name]]',
       'networkComponents[id, status, speed, maxSpeed, name, macAddress, primaryIpAddress, port, primarySubnet]',
       'lastOperatingSystemReload.id',
       'blockDevices',
       'blockDeviceTemplateGroup[id, name, globalIdentifier]' ]
      super + [sub_mask]
    end #default_object_mask


    ##
    # Retrive the virtual server with the given server ID from the API
    #
    def self.server_with_id(softlayer_client, server_id, options = {})
      if options.has_key?(:object_mask)
        object_mask = options[:object_mask]
      else
        object_mask = default_object_mask()
      end

      required_properties_mask = ['id']
      
      service = softlayer_client["Virtual_Guest"]
      service = service.object_mask([object_mask, required_properties_mask])

      server_data = service.object_with_id(server_id).getObject()

      return VirtualServer.new(softlayer_client, server_data)
    end

    ##
    # Retrieve a list of virtual servers from the account.
    #
    # You may filter the list returned by adding options:
    # * <b>+:hourly+</b> (boolean) - Include servers billed hourly in the list
    # * <b>+:monthly+</b> (boolean) - Include servers billed monthly in the list
    # * <b>+:tags+</b> (array) - an array of strings representing tags to search for on the instances
    # * <b>+:cpus+</b> (int) - return virtual servers with the given number of (virtual) CPUs
    # * <b>+:memory+</b> (int) - return servers with at least the given amount of memory (in MB. e.g. 4096 = 4GB)
    # * <b>+:hostname+</b> (string) - return servers whose hostnames match the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:domain+</b> (string) - filter servers to those whose domain matches the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:local_disk+</b> (boolean) - include servers that do, or do not, have local disk storage
    # * <b>+:datacenter+</b> (string) - find servers whose short data center name (e.g. dal05, sjc01) matches the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:nic_speed+</b> (int) - include servers with the given nic speed (in MBPS, usually 10, 100, or 1000)
    # * <b>+:public_ip+</b> (string) - return servers whose public IP address matches the query string given (see ObjectFilter::query_to_filter_operation)
    # * <b>+:private_ip+</b> (string) - same as :public_ip, but for private IP addresses
    #
    # Additionally you may provide options related to the request itself:
    # * <b>+:object_mask+</b> (string, hash, or array) - The object mask of properties you wish to receive for the items returned If not provided, the result will use the default object mask
    # * <b>+:result_limit+</b> (hash with :limit, and :offset keys) - Limit the scope of results returned.
    #
    def self.find_servers(softlayer_client, options_hash = {})
      if(!options_hash.has_key? :object_mask)
        object_mask = VirtualServer.default_object_mask
      else
        object_mask = options_hash[:object_mask]
      end

      object_filter = {}

      option_to_filter_path = {
        :cpus => "virtualGuests.maxCpu",
        :memory => "virtualGuests.maxMemory",
        :hostname => "virtualGuests.hostname",
        :domain => "virtualGuests.domain",
        :local_disk => "virtualGuests.localDiskFlag",
        :datacenter => "virtualGuests.datacenter.name",
        :nic_speed => "virtualGuests.networkComponents.maxSpeed",
        :public_ip => "virtualGuests.primaryIpAddress",
        :private_ip => "virtualGuests.primaryBackendIpAddress"
      }
      
      if options_hash.has_key?(:local_disk) then
        options_hash[:local_disk] = options_hash[:local_disk] ? 1 : 0
      end

      # For each of the options in the option_to_filter_path map, if the options hash includes
      # that particular option, add a clause to the object filter that filters for the matching
      # value
      option_to_filter_path.each do |option, filter_path|
        object_filter.merge!(SoftLayer::ObjectFilter.build(filter_path, options_hash[option])) if options_hash.has_key?(option)
      end

      # Tags get a much more complex object filter operation so we handle them separately
      if options_hash.has_key?(:tags)
        object_filter.merge!(SoftLayer::ObjectFilter.build("virtualGuests.tagReferences.tag.name", {
          'operation' => 'in',
          'options' => [{
            'name' => 'data',
            'value' => options_hash[:tags]
            }]
          } ));
      end

      required_properties_mask = ['id']

      service = softlayer_client['Account']
      service = service.object_mask([object_mask, required_properties_mask])
      service = service.object_filter(object_filter) if object_filter && !object_filter.empty?

      if options_hash.has_key?(:result_limit)
        offset = options[:result_limit][:offset]
        limit = options[:result_limit][:limit]

        service = service.result_limit(offset, limit)
      end

      case
      when options_hash[:hourly] && options_hash[:monthly]
        virtual_server_data = service.getVirtualGuests()
      when options_hash[:hourly]
        virtual_server_data = service.getHourlyVirtualGuests()
      when options_hash[:monthly]
        virtual_server_data = service.getMonthlyVirtualGuests()
      else
        virtual_server_data = service.getVirtualGuests()
      end

      virtual_server_data.collect { |server_data| VirtualServer.new(softlayer_client, server_data) }
    end
  end #class VirtualServer
end