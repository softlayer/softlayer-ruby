module SoftLayer
  class Server  < SoftLayer::ModelBase
  end

  class BareMetalServer < Server
    def BareMetalServer.find_servers(softlayer_service, options)
      if options.has_key? :tags
      end
      
    end
  end

  class VirtualServer < Server
  end
end
