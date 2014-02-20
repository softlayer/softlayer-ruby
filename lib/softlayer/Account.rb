require 'rubygems'
require 'json'

module SoftLayer
  class Account < SoftLayer::ModelBase
    attr_reader :account_id
    attr_reader :bare_metal_servers, :virtual_servers, :servers

    # Retrieve the default account object from the given service.
    # This should be a SoftLayer::Service with the service id of 
    # SoftLayer_Account.
    #
    # account_service = SoftLayer::Service.new("SoftLayer_Account")
    # account = SoftLayer::Account.default_account(account_service)
    #
    def self.default_account(account_service)
      network_hash = account_service.getObject()
      new(account_service, network_hash)
    end
    
    def initialize(softlayer_service, network_hash = {})
      super softlayer_service, network_hash
      @bare_metal_servers = nil
      @virtual_servers = nil
    end
    
    # the account_id field comes from the hash
    def account_id
      value = @sl_hash[:id]
    end
    
    def servers
      return self.bare_metal_servers + self.virtual_servers
    end

    # def update_bare_metal_servers?
    #   elapsed_time = @last_bare_metal_servers_update - Time.now()
    #   return elapsed_time > bare_metal_servers_refresh_interval;
    # end
    # 
    # def updated_bare_metal_servers
    #   hardware_service = self.softlayer_service.related_service_named("SoftLayer_Hardware")
    #   bare_metal_data = self.softlayer_service.getHardware()
    # 
    #   bare_metal_data.collect { |server_data| BareMetalServer.new(hardware_service, server_data) }
    # end
    # 
    # def bare_metal_servers
    #   if update_bare_metal_servers?
    #     @bare_metal_servers = updated_bare_metal_servers
    #   end
    # 
    #   return @bare_metal_servers
    # end

    def bare_metal_servers
      self.update_servers
      return @bare_metal_servers
    end

    def virtual_servers
      self.update_servers
      return @virtual_servers
    end

    def update_servers
      hardware_service = self.softlayer_service.related_service_named("SoftLayer_Hardware")
      bare_metal_data = self.softlayer_service.getHardware()
      @bare_metal_servers = bare_metal_data.collect { |server_data| BareMetalServer.new(hardware_service, server_data) }

      virtual_guest_service = self.softlayer_service.related_service_named("SoftLayer_Virtual_Guest")
      virtual_server_data = self.softlayer_service.getVirtualGuests()
      @virtual_servers = virtual_server_data.collect { |server_data| VirtualServer.new(virtual_guest_service, server_data) }
    end
  end
end