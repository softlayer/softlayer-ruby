#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # A Data Center in the SoftLayer network
  #
  # This class corresponds to the SoftLayer_Location++ data type:
  #
  # http://sldn.softlayer.com/reference/datatypes/SoftLayer_Location
  #
  # Although in this context it is used to represent a data center and
  # not the more general class of locations that that data type can
  # represent.

  class Datacenter < SoftLayer::ModelBase

    ##
    # :attr_reader:
    # A short location description
    sl_attr :name

    ##
    # :attr_reader: long_name
    # A longer location description
    sl_attr :long_name, "longName"

    ##
    # Return the datacenter with the given name ('sng01' or 'dal05')
    def self.datacenter_named(name, client = nil)
      datacenters(client).find{ | datacenter | datacenter.name == name.to_s.downcase }
    end

    ##
    # Return a list of all the datacenters
    #
    # If the client parameter is not provided, the routine
    # will try to use Client::defult_client.  If no client
    # can be found, the routine will raise an exception
    #
    # This routine will only retrieve the list of datacenters from
    # the network once and keep it in memory unless you
    # pass in force_reload as true.
    #
    @@data_centers = nil
    def self.datacenters(client = nil, force_reload = false)
      softlayer_client = client || Client.default_client
      raise "Datacenter.datacenters requires a client to call the network API" if !softlayer_client

      if(!@@data_centers || force_reload)
        datacenters_data = softlayer_client[:Location].getDatacenters
        @@data_centers = datacenters_data.collect { | datacenter_data | self.new(softlayer_client, datacenter_data) }
      end

      @@data_centers
    end
  end
end
