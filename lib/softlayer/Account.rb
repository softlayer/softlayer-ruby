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
        bare_metal_data = self.softlayer_client['Account'].getHardware()
        bare_metal_data.collect { |server_data| BareMetalServer.new(self.softlayer_client, server_data) }
      end
    end

    softlayer_resource :virtual_servers do |virtual_servers|
      virtual_servers.refresh_every 5 * 60
      virtual_servers.update do
        virtual_server_data = self.softlayer_client['Account'].getVirtualGuests()
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
      value = @sl_hash[:id]
    end

    # return a list combining the virtual servers and bare metal servers in a single list
    def servers
      return self.bare_metal_servers + self.virtual_servers
    end
  end
end