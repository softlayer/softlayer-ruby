#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  #
  # This class is used to order a hardware server using a product package.
  #
  # Ordering a server using a product package is a more complex process than
  # ordering with simple attributes (as is done by the BareMetalServerOrder class).
  # However with that complexity comes the the ability to specify the configuration
  # of the server in exacting detail.
  #
  # To use this class, you first select a product package. The product package
  # defines the base configuration, the chassis, of the server as well as the set of configuration
  # options available for that chassis. To fully configure the server you must select
  # the value for each configuration option.
  #
  # This class roughly Corresponds to the SoftLayer_Container_Product_Order_Hardware_Server
  # data type in the SoftLayer API
  #
  # http://sldn.softlayer.com/reference/datatypes/SoftLayer_Container_Product_Order_Hardware_Server
  #
  class BareMetalServerOrder_Package < Server
    # The following properties are required in a server order.

    # The product package object (an instance of SoftLayer::ProductPackage) identifying the base
    # configuration for the server. A list of Bare Metal Server product packages is returned by
    # SoftLayer::ProductPackage.bare_metal_server_packages
    attr_reader :package

    # An instance of SoftLayer::Datacenter. The server will be provisioned in this data center.
    # The set of datacenters available is determined by the package and may be obtained from
    # the SoftLayer::ProductPackage object using the #datacenter_options method.
    attr_accessor :datacenter

    # The hostname of the server being created (i.e. 'sldn' is the hostname of sldn.softlayer.com).
    attr_accessor :hostname

    # The domain of the server being created (i.e. 'softlayer.com' is the domain of sldn.softlayer.com)
    attr_accessor :domain

    # The value of this property should be a hash. The keys of the hash are ProdcutItemCategory
    # codes (like 'os' and 'ram') while the values may be Integers or Objects. The Integer values
    # should be the +id+ of a +SoftLayer_Product_Item_Price+ representing the configuration option
    # chosen for that category. Objects must respond to the +price_id+ message and return an integer
    # that is the +id+ of a +SoftLayer_Product_Item_Price+. Instances of the ProductConfigurationOption
    # class behave this way.
    #
    # At a minimum, the configuation_options should include entries for each of the categories
    # required by the package (i.e. those returned from ProductPackage#required_categories)
    attr_accessor :configuration_options

    # The following properties are optional, but allow further fine tuning of
    # the server

    # An array of the ids of SSH keys to install on the server upon provisioning
    # To obtain a list of existing SSH keys, call getSshKeys on the SoftLayer_Account service:
    #     client['Account'].getSshKeys()
    attr_accessor :ssh_key_ids

    # The URI of a script to execute on the server after it has been provisioned. This may be
    # any object which accepts the to_s message. The resulting string will be passed to SoftLayer API.
    attr_accessor :provision_script_URI

    ##
    # You initialize a BareMetalServerOrder_Package by passing in the package that you
    # are ordering from.
    def initialize(package, client = nil)
      @softlayer_client = client || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !@softlayer_client

      @package = package
      @configuration_options = []
    end

    ##
    # Present the order for verification by the SoftLayer ordering system.
    # The order is verified, but not executed. This should not
    # change the billing of your account.
    #
    # If you add a block to the method call, it will receive the product
    # order template before it is sent to the API. You may **carefully** make
    # changes to the template to provide specialized configuration.
    #
    def verify
      product_order = hardware_order
      product_order = yield product_order if block_given?
      softlayer_client["Product_Order"].verifyOrder(product_order)
    end

    ##
    # Submit the order to be executed by the SoftLayer ordering system.
    # If successful this will probably result in additional billing items
    # applied to your account!
    #
    # If you add a block to the method call, it will receive the product
    # order template before it is sent to the API. You may **carefully** make
    # changes to the template to provide specialized configuration.
    #
    # The return value of this call is a product order receipt. After
    # submitting the order, it will proceed to Sales for authorization.
    #
    def place_order!
      product_order = hardware_order
      product_order = yield product_order if block_given?
      softlayer_client["Product_Order"].placeOrder(product_order)
    end

    protected

    ##
    # Construct and return a hash representing a +SoftLayer_Container_Product_Order_Hardware_Server+
    # based on the configuration options given.
    def hardware_order
      product_order = {
        'packageId' => @package.id,
        'useHourlyPricing' => false,
        'hardware' => {
          'hostname' => @hostname,
          'domain' => @domain
        }
      }

      product_order['location'] = @datacenter.id if @datacenter
      product_order['sshKeys'] = [{ 'sshKeyIds' => @ssh_key_ids }] if @ssh_key_ids
      product_order['provisionScripts'] = [@provision_script_URI.to_s] if @provision_script_URI

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
  end # BareMetalServerOrder_Package
end # SoftLayer