require 'rubygems'
require 'json'

module SoftLayer
  class Account < SoftLayer::ModelBase
    include ::SoftLayer::ModelResource

    attr_reader :account_id
    attr_reader :servers

    softlayer_resource :bare_metal_servers do |bare_metal|
      bare_metal.refresh_every 5 * 60
      bare_metal.update do
        bare_metal_data = self.softlayer_service.getHardware()
        hardware_service = softlayer_service.related_service_named("SoftLayer_Hardware")
        bare_metal_data.collect { |server_data| BareMetalServer.new(hardware_service, server_data) }
      end
    end

    softlayer_resource :virtual_servers do |virtual_servers|
      virtual_servers.refresh_every 5 * 60
      virtual_servers.update do
        virtual_server_data = self.softlayer_service.getVirtualGuests()
        virtual_guest_service = softlayer_service.related_service_named("SoftLayer_Virtual_Guest")
        virtual_server_data.collect { |server_data| VirtualServer.new(virtual_guest_service, server_data) }
      end
    end

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
  end
end