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
  ##
  # Each SoftLayer ProductPackage provides information about ordering a product
  # or service from SoftLayer.
  #
  # === Configuration Option Categories
  # A important companion to Product Packages are configuration option +Categories+.
  # Each Category represents a set of options that you may choose from to configure
  # one attribute of the product or service you are ordering.
  #
  # For example, in a package for ordering a server, the 'os' Category contains
  # the available choices for operating systems that may be provisioned on the server.
  #
  # When you construct an order based on that package, you will make one selection from
  # the 'os' category and put it into the order.
  #
  # Categories are identified by +categoryCode+. Examples of category codes
  # include 'os', 'ram', and 'port_speed'.
  #
  # === Package Configuration
  # A package also has a Configuration. A Configuration specifies which
  # Categories are valid in an order and, more importantly, which Categories
  # are **required** in any order that uses the ProductPackage.
  #
  # When constructing an order, you **must** provide an option for each of the Categories
  # that the Configuration marks as required (and you must supply a value even if the
  # Category only has one choice)
  #
  # === Regions/Locations
  #
  # Not all products and services are available in all the SoftLayer data centers. The +regions+
  # property of a ProductPackage indicates in which data centers the products in the package
  # can be ordered.
  #
  class ProductPackage < ModelBase
    VIRTUAL_SERVER_PACKAGE_KEY = 'VIRTUAL_SERVER_INSTANCE'
    BARE_METAL_INSTANCE_PACKAGE_KEY = 'BARE_METAL_CORE'
    BARE_METAL_SERVER_PACKAGE_KEY = 'BARE_METAL_CPU'

    ##
    # Returns an array of all the configuration categories required by the package
    def required_option_categories
      self.configuration.select { |option_category| option_category['isRequired'] != 0 }.collect { |option_category| option_category['itemCategory']['categoryCode'] }
    end

    ##
    # Requests a list (array) of ProductPackages whose key names match the
    # one passed in.
    #
    def self.packages_with_key_name(client, key_name)
      filter = SoftLayer::ObjectFilter.build('type.keyName') { is(key_name) }
      packages_data = client['Product_Package'].object_filter(filter).object_mask(self.default_object_mask).getAllObjects
      packages_data.collect { |package_data| ProductPackage.new(client, package_data) }
    end

    ##
    # Returns the ProductPackage of the package used to order virtual servers
    # At the time of this writing, the code assumes this package is unique
    #
    def self.virtual_server_package(client)
      packages_with_key_name(client, VIRTUAL_SERVER_PACKAGE_KEY).first
    end

    ##
    # Returns the ProductPackage of the package used to order Bare Metal Instances
    # At the time of this writing, the code assumes this package is unique
    #
    def self.bare_metal_instance_package(client)
      packages_with_key_name(client, BARE_METAL_INSTANCE_PACKAGE_KEY).first
    end

    ##
    # Returns an array of ProductPackages, each of which can be used
    # as the foundation to order a bare metal server.
    def self.bare_metal_server_packages(client)
      packages_with_key_name(client, BARE_METAL_SERVER_PACKAGE_KEY)
    end

    protected

    def self.default_object_mask
      "mask[id,name,description,regions[keyname,description],configuration[isRequired,itemCategory[categoryCode]]]"
    end

  end
end # SoftLayer