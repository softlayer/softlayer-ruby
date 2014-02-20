module SoftLayer
  class Server  < SoftLayer::ModelBase
  end

  class BareMetalServer < Server
  end

  class VirtualServer < Server
  end
end
