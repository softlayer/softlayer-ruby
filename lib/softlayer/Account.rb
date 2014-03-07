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

    # makes a network request and returns the servers matching a given set of criteria
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

      # For each of the options in teh option_to_filter_path map, if the options hash includes
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
      
      bare_metal_data = service.getHardware()
      bare_metal_data.collect { |server_data| BareMetalServer.new(self.softlayer_client, server_data) }
    end
  end
end