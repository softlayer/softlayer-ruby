module SoftLayer
  # SLDN Service identifiers.  These are used to distinguish which IMS service
  # a server originated from
  :SoftLayer_Hardware        # corresponds to SoftLayer_Hardware
  :SoftLayer_Virtual_Guest   # corresponds to SoftLayer_Virtual_Guest
  
  class Server
    # the object ID of the server.  It is possible to have two servers with
    # identical serverIDs if they came from separate IMS services (i.e. one is hardware)
    # and one is a virtual guest.
    attr_reader :serverID
    
    # The full name of the server.  This is usually the Fully Qualified Domain Name
    attr_reader :name
    
    # The text of any notes associated with the server.
    attr_reader :notes
  
    # returns :SoftLayer_Hardware for servers reported through the hardware service
    # and :SoftLayer_Virtual_Guest for servers reported through that service.
    attr_reader :sldn_service_id
    
    # The primary ip address of the server (expressed as a string)
    # For most servers primary Public IP address
    attr_reader :primary_ip_address
  end
      
  class BareMetalServer < Server
  end
  
  class VirtualServer < Server
  end
end
