#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  #
  # This class is used to order a virtual server using a product package.
  #
  # Ordering a server using a product package is a more complex process than
  # ordering with simple attributes (as is done by the VirtualServerServerOrder class).
  # However with that complexity comes the the ability to specify the configuration
  # of the server in exacting detail.
  #
  # To use this class, you first select a product package. The product package
  # defines the base configuration of the server as well as the set of configuration
  # options available for that server. To fully configure the server you must select
  # the value for each configuration option.
  #
  # This class roughly Corresponds to the SoftLayer_Container_Product_Order_Virtual_Guest
  # data type in the SoftLayer API
  #
  # http://sldn.softlayer.com/reference/datatypes/SoftLayer_Container_Product_Order_Virtual_Guest
  #
  class VirtualServerOrder_Package < Server
    # The following properties are required in a server order.

    # The product package object (an instance of SoftLayer::ProductPackage) identifying the base
    # configuration for the server. A Virtual Server product package is returned by
    # SoftLayer::ProductPackage.virtual_server_package
    attr_reader :package

    # An instance of SoftLayer::Datacenter. The server will be provisioned in this data center.
    # The set of datacenters available is determined by the package and may be obtained from
    # the SoftLayer::ProductPackage object using the #datacenter_options method.
    attr_accessor :datacenter

    # The hostname of the server being created (i.e. 'sldn' is the hostname of sldn.softlayer.com).
    attr_accessor :hostname

    # The domain of the server being created (i.e. 'softlayer.com' is the domain of sldn.softlayer.com)
    attr_accessor :domain

    # The value of this property should be a hash. The keys of the hash are ProductItemCategory
    # codes (like 'os' and 'ram') while the values may be Integers or Objects. The Integer values
    # should be the +id+ of a +SoftLayer_Product_Item_Price+ representing the configuration option
    # chosen for that category. Objects must respond to the +price_id+ message and return an integer
    # that is the +id+ of a +SoftLayer_Product_Item_Price+. Instances of the ProductConfigurationOption
    # class behave this way.
    #
    # At a minimum, the configuration_options should include entries for each of the categories
    # required by the package (i.e. those returned from ProductPackage#required_categories)
    attr_accessor :configuration_options

    # The following properties are optional, but allow further fine tuning of
    # the server

    # Boolean, If true, an hourly server will be ordered, otherwise a monthly server will be ordered
    # Corresponds to +useHourlyPricing+ in the SoftLayer_Container_Product_Order_Virtual_Guest container
    # documentation
    attr_accessor :hourly

    # An instance of the SoftLayer::ImageTemplate class.  Represents the image template that should
    # be installed on the server.
    attr_accessor :image_template

    # Integer, The id of the public VLAN this server should join
    # Corresponds to +primaryNetworkComponent.networkVlan.id+ in the +createObject+ documentation
    attr_accessor :public_vlan_id

    # Integer, The id of the private VLAN this server should join
    # Corresponds to +primaryBackendNetworkComponent.networkVlan.id+ in the +createObject+ documentation
    attr_accessor :private_vlan_id

    # The URI of a script to execute on the server after it has been provisioned. This may be
    # any object which accepts the to_s message. The resulting string will be passed to SoftLayer API.
    attr_accessor :provision_script_uri

    # The URI of a script to execute on the server after it has been provisioned. This may be
    # any object which accepts the to_s message. The resulting string will be passed to SoftLayer API.
    #
    # DEPRECATION WARNING: This attribute is deprecated in favor of provision_script_uri
    # and will be removed in the next major release.
    attr_accessor :provision_script_URI

    # An array of the ids of SSH keys to install on the server upon provisioning
    # To obtain a list of existing SSH keys, call getSshKeys on the SoftLayer_Account service:
    #     client[:Account].getSshKeys()
    attr_accessor :ssh_key_ids

    # String, User metadata associated with the instance
    # Corresponds to +userData+ in the +SoftLayer_Virtual_Guest+ documentation
    attr_accessor :user_metadata

    ##
    # You initialize a VirtualServerOrder_Package by passing in the package that you
    # are ordering from.
    def initialize(client = nil)
      @softlayer_client = client || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !@softlayer_client

      @configuration_options = []
      @package               = SoftLayer::ProductPackage.virtual_server_package(@softlayer_client)
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
      product_order = virtual_server_order
      product_order = yield product_order if block_given?
      softlayer_client[:Product_Order].verifyOrder(product_order)
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
      product_order = virtual_server_order
      product_order = yield product_order if block_given?
      softlayer_client[:Product_Order].placeOrder(product_order)
    end

    protected

    ##
    # Construct and return a hash representing a +SoftLayer_Container_Product_Order_Virtual_Guest+
    # based on the configuration options given.
    def virtual_server_order
      product_order = {
        'packageId'        => @package.id,
        'useHourlyPricing' => !!@hourly,
        'virtualGuests'    => [{
                                 'domain'   => @domain,
                                 'hostname' => @hostname
                               }]
      }

      #Note that the use of image_template and SoftLayer::ProductPackage os/guest_diskX configuration category
      #item prices is mutually exclusive.
      product_order['imageTemplateGlobalIdentifier']  = @image_template.global_id         if @image_template
      product_order['location']                       = @datacenter.id                    if @datacenter
      product_order['provisionScripts']               = [@provision_script_URI.to_s]      if @provision_script_URI
      product_order['provisionScripts']               = [@provision_script_uri.to_s]      if @provision_script_uri
      product_order['sshKeys']                        = [{ 'sshKeyIds' => @ssh_key_ids }] if @ssh_key_ids
      product_order['virtualGuests'][0]['userData']   = @user_metadata                    if @user_metadata
      product_order['primaryNetworkComponent']        = { "networkVlan" => { "id" => @public_vlan_id.to_i } } if @public_vlan_id
      product_order['primaryBackendNetworkComponent'] = { "networkVlan" => {"id" => @private_vlan_id.to_i } } if @private_vlan_id

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
  end # VirtualServerOrder_Package
end # SoftLayer
