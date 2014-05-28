#
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

module SoftLayer
  #
  # This class is used to order a hardware server with the full set of 
  # configuration options of a Bare Metal Server.  Hardware servers
  # may also be ordered with a more streamlined set of configuration
  # options using the BareMetalInstanceOrder class.
  #
  # This class roughly corresponds to the SoftLayer_Container_Product_Order_Hardware_Server
  # data type in the SoftLayer API
  #
  # http://sldn.softlayer.com/reference/datatypes/SoftLayer_Container_Product_Order_Hardware_Server
  #
  class BareMetalServerOrder < Server
    # The following properties are required in a server order.
    
    # The product package identifying the base configuration for the server.
    # a list of Bare Metal Server product packages is returned by 
    # SoftLayer::ProductPackage.bare_metal_server_packages
    attr_reader :package

    # SoftLayer Region Keyname indicating where the server should be provisioned
    # A list of key names is included in the return value from ProductPackage#locations
    attr_accessor :location 

    # The hostname of the server being created (i.e. 'sldn' is the hostname of sldn.softlayer.com).
    attr_accessor :hostname

    # The domain of the server being created (i.e. 'softlayer.com' is the domain of sldn.softlayer.com)
    attr_accessor :domain

    # The value of this property should be a hash. The keys of the hash are ProdcutItemCategory
    # codes (like 'os' and 'ram') while the values may either be Integers or objects that respond 
    # to the +price_id+ message by returning an Integer.  The Integer values should be the +id+
    # of a SoftLayer_Product_Item_Price representing the configuration option chosen for that category.
    #
    # At a minimum, the configuation_options should include entries for each of the categories
    # required by the package (i.e. those returned from ProductPackage#required_categories)
    attr_accessor :configuration_options
    
    # The following properties are optional, but allow further fine tuning of
    # the server

    # The maximum port speed for the newly created server in Mbps.  If omitted the default port speed
    # will be used.  Typical values are 10, 100, or 1000
    attr_accessor :max_port_speed
 
    # An array of SSH pubic keys to add to the root user of the server being provisioned.
    # This attribute is ignored for Servers that are provisioned with Microsoft Windows operating systems
    attr_accessor :ssh_keys

    # The URI of a script to execute on the server after it has been provisioned. This may be 
    # any object which accepts the to_s message.  The resulting string will be passed to SoftLayer API.
    attr_accessor :provision_script_URI
    
    
    ##
    # You initialize a BareMetalServerOrder by passing in the package that you
    # are ordering from.
    def initialize(client,package)
      @softlayer_client = client
      @package = package
    end
    
    def verify_order
      @softlayer_client["Product_Order"].verifyOrder(hardware_order)
    end

    def place_order!
    end
  
    protected
    
    ##
    # Construct and return a hash representing a SoftLayer_Container_Product_Order_Hardware_Server
    # based on the configuration options given.
    def hardware_order
      product_order = {
        'packageId' => @package.id,
        'location' => @location,
        'useHourlyPricing' => false,
        'hardware' => {
          'hostname' => @hostname,
          'domain' => @domain
        }
      }

      product_order['prices'] = @configuration_options.collect do |key, value|
        if value.respond_to?(:price_id)
          price_id = value.price_id
        else
          price_id = value.to_i
        end

        { 'id' => price_id }
      end

      product_order
    end
  end
end