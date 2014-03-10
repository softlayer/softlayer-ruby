require 'rubygems'
require 'json'

module SoftLayer
  class Account < SoftLayer::ModelBase
    include ::SoftLayer::ModelResource

    softlayer_resource :bare_metal_servers do |bare_metal|
      bare_metal.should_update_if do
        @last_bare_metal_update ||= Time.at(0)
        (Time.now - @last_bare_metal_update) > 5 * 60  # update every 5 minutes
      end

      bare_metal.to_update do
        @last_bare_metal_update = Time.now

        bare_metal_data = self.softlayer_client['Account'].object_mask(BareMetalServer.default_object_mask).getHardware()
        bare_metal_data.collect { |server_data| BareMetalServer.new(self.softlayer_client, server_data) }
      end
    end

    softlayer_resource :virtual_servers do |virtual_servers|
      virtual_servers.should_update_if do
        @last_virtual_server_update ||= Time.at(0)
        (Time.now - @last_virtual_server_update) > 5 * 60  # update every 5 minutes
      end

      virtual_servers.to_update do
        @last_virtual_server_update = Time.now
        virtual_server_data = self.softlayer_client['Account'].object_mask(VirtualServer.default_object_mask).getVirtualGuests()
        virtual_server_data.collect { |server_data| VirtualServer.new(self.softlayer_client, server_data) }
      end
    end

    ## 
    # The tickets resource consists of all open tickets, and tickets closed
    # "recently"
    softlayer_resource :tickets do |tickets|
      tickets.should_update_if do
        puts "Checking to see if I should update tickets"
        @last_ticket_update ||= Time.at(0)
        (Time.now - @last_ticket_update) > 5 * 60 #update every 5 minutes
      end

      tickets.to_update do
        @last_ticket_update = Time.now

        open_ticket_data = self.softlayer_client["Account"].object_mask(Ticket.default_object_mask).getOpenTickets()
        recently_closed_data = self.softlayer_client["Account"].object_mask(Ticket.default_object_mask).getTicketsClosedInTheLastThreeDays()

        open_tickets = open_ticket_data.collect { |ticket_data| Ticket.new(self.softlayer_client, ticket_data) }
        closed_tickets = recently_closed_data.collect { |ticket_data| Ticket.new(self.softlayer_client, ticket_data) }

        open_tickets + closed_tickets
      end
    end

    ##
    # Retrieve the default account object from the given service.
    # This should be a SoftLayer::Service with the service id of
    # SoftLayer_Account.
    #
    # account_service = SoftLayer::Service.new("SoftLayer_Account")
    # account = SoftLayer::Account.account_for_client(account_service)
    #
    def self.account_for_client(softlayer_client)
      account_service = softlayer_client['Account']
      network_hash = account_service.getObject()
      new(softlayer_client, network_hash)
    end

    # the account_id field comes from the hash
    def account_id
      @sl_hash[:id]
    end

    # return a list combining the virtual servers and bare metal servers in a single list
    def servers
      return self.bare_metal_servers + self.virtual_servers
    end

    ##
    # retrieve a list of hardware servers from the account
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

    def find_bare_metal_servers!(options_hash = {})
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

      service = self.softlayer_client['Account']
      service = service.object_mask(object_mask) if object_mask && !object_mask.empty?
      service = service.object_filter(object_filter) if object_filter && !object_filter.empty?

      if options_hash.has_key?(:result_limit)
        offset = options[:result_limit][:offset]
        limit = options[:result_limit][:limit]

        service = service.result_limit(offset, limit)
      end
      
      bare_metal_data = service.getHardware()
      bare_metal_data.collect { |server_data| BareMetalServer.new(self.softlayer_client, server_data) }
    end

    ##
    # retrieve a list of virtual servers from the account
    # You may filter the list returned by adding options:
    # * :hourly (boolean) - Include servers billed hourly in the list
    #   :monthly (boolean) - Include servers billed monthly in the list
    #   :tags (array) - an array of strings representing tags to search for on the instances
    #   :cpus (int) - return virtual servers with the given number of (virtual) CPUs
    #   :memory (int) - return servers with at least the given amount of memory
    #   :hostname (string) - return servers whose hostnames match the query string given (see ObjectFilter::query_to_filter_operation)
    #   :domain (string) - filter servers to those whose domain matches the query string given (see ObjectFilter::query_to_filter_operation)
    #   :local_disk (boolean) - include servers that do, or do not, have local disk storage
    #   :datacenter (string) - find servers whose data center name matches the query string given (see ObjectFilter::query_to_filter_operation)
    #   :nic_speed (int) - include servers with the given nic speed (in MBPS)
    #   :public_ip (string) - return servers whose public IP address matches the query string given (see ObjectFilter::query_to_filter_operation)
    #   :private_ip (string) - same as :public_ip, but for private IP addresses
    #
    # Additionally you may provide options related to the request itself:
    # *  :object_mask (string, hash, or array) - The object mask of properties you wish to receive for the items returned If not provided, the result will use the default object mask
    #    :result_limit (hash with :limit, and :offset keys) - Limit the scope of results returned.

    def find_virtual_servers!(options_hash = {})
      if(!options_hash.has_key? :object_mask)
        object_mask = VirtualServer.defaultObject_mask
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

      service = self.softlayer_client['Account']
      service = service.object_mask(object_mask) if object_mask && !object_mask.empty?
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

      virtual_server_data = service.getVirtualGuests()
      virtual_server_data.collect { |server_data| VirtualServer.new(self.softlayer_client, server_data) }
    end

  end
end