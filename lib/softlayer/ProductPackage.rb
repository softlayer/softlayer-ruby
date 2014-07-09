#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

require 'json'

module SoftLayer
  ##
  # Each SoftLayer ProductPackage provides information about ordering a product
  # or service from SoftLayer.
  #
  # === Product Item Categories
  # A important companion to Product Packages are ProductItemCategories.
  # Each ProductItemCategory represents a set of options that you may choose from when
  # configuring an attribute of the product or service you are ordering.
  #
  # ProductItemCategories are identified by +categoryCode+. Examples of category codes
  # include 'os', 'ram', and 'port_speed'.
  #
  # For example, in a package for ordering a server, the 'os' ProductItemCategory contains
  # the available choices for operating systems that may be provisioned on the server.
  #
  # When you construct an order based on that package, you will make one selection from
  # the 'os' category and put it into the order.
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
  class ProductPackage < ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # A friendly, readable name for the package
    sl_attr :name

    ##
    # The list of locations where this product package is available.
    sl_attr :available_locations, 'availableLocations'

    ##
    # The set of product categories needed to make an order for this product package.
    #
    sl_dynamic_attr :configuration do |resource|
      resource.should_update? do
        # only retrieved once per instance
        @configuration == nil
      end

      resource.to_update do
        #
        # We call +SoftLayer_Product_Package+ to get the configuration for this package.
        #
        # Unfortunately, even though this call includes +SoftLayer_Product_Item_Category+ entities, it does not have the context
        # needed to find the active price items for that category.
        #
        # Instead, we make a second call, this time to +SoftLayer_Product_Package::getCategories+. That method incorporates a complex
        # filtering mechanism on the server side to give us a list of the categories, groups, and prices that are valid for the current
        # account at the current time. We construct the ProductItemCategory objects from the results we get back.
        #
        configuration_data = softlayer_client['Product_Package'].object_with_id(self.id).object_mask("mask[isRequired,itemCategory.categoryCode]").getConfiguration()

        # We sort of invert the information and create a map from category codes to a boolean representing
        # whether or not they are required.
        required_by_category_code = configuration_data.inject({}) do |required_by_category_code, config_category|
          required_by_category_code[config_category['itemCategory']['categoryCode']] = (config_category['isRequired'] != 0)
          required_by_category_code
        end

        # This call to getCategories is the one that does lots of fancy back-end filtering for us
        categories_data = softlayer_client['Product_Package'].object_with_id(self.id).getCategories()

        # Run though the categories and for each one that's in our config, create a SoftLayer::ProductItemCategory object.
        # Conveniently the +keys+ of the required_by_category_code gives us a list of the category codes in the configuration
        config_categories = required_by_category_code.keys
        categories_data.collect do |category_data|
          if config_categories.include? category_data['categoryCode']
            SoftLayer::ProductItemCategory.new(softlayer_client, category_data, required_by_category_code[category_data['categoryCode']])
          else
            nil
          end
        end.compact
      end
    end

    ##
    # Returns an array of the required categories in this package
    def required_categories
      configuration.select { |category| category.required? }
    end

    ##
    # Returns the product category with the given category code (or nil if one cannot be found)
    def category(category_code)
      configuration.find { |category| category.categoryCode == category_code }
    end

    def datacenter_options
      available_locations.collect { |location_data| Datacenter::datacenter_named(location_data["location"]["name"], self.softlayer_client) }.compact
    end

    def service
      softlayer_client['Product_Package'].object_with_id(self.id)
    end

    ##
    # Requests a list (array) of ProductPackages whose key names match the
    # one passed in.
    #
    def self.packages_with_key_name(key_name, client = nil)
      softlayer_client = client || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      filter = SoftLayer::ObjectFilter.new do |filter|
        filter.accept('type.keyName').when_it is(key_name)
      end

      filtered_service = softlayer_client['Product_Package'].object_filter(filter).object_mask(self.default_object_mask('mask'))
      packages_data = filtered_service.getAllObjects
      packages_data.collect { |package_data| ProductPackage.new(softlayer_client, package_data) }
    end

    ##
    # Requests a list (array) of ProductPackages whose key names match the
    # one passed in.
    #
    def self.package_with_id(package_id, client = nil)
      softlayer_client = client || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      package_data = softlayer_client['Product_Package'].object_with_id(package_id).object_mask(self.default_object_mask('mask')).getObject
      ProductPackage.new(softlayer_client, package_data)
    end

    ##
    # Returns the ProductPackage of the package used to order virtual servers
    # At the time of this writing, the code assumes this package is unique
    #
    # 'VIRTUAL_SERVER_INSTANCE' is a "well known" constant for this purpose
    def self.virtual_server_package(client = nil)
      packages_with_key_name('VIRTUAL_SERVER_INSTANCE', client).first
    end

    ##
    # Returns the ProductPackage of the package used to order Bare Metal Servers
    # with simplified configuration options.
    #
    # At the time of this writing, the code assumes this package is unique
    #
    # 'BARE_METAL_CORE' is a "well known" constant for this purpose
    def self.bare_metal_instance_package(client = nil)
      packages_with_key_name('BARE_METAL_CORE', client).first
    end

    ##
    # Returns an array of ProductPackages, each of which can be used
    # as the foundation to order a bare metal server.
    #
    # 'BARE_METAL_CPU' is a "well known" constant for this purpose
    def self.bare_metal_server_packages(client = nil)
      packages_with_key_name('BARE_METAL_CPU', client)
    end

    protected

    def self.default_object_mask(root)
      "#{root}[id,name,description,availableLocations.location]"
    end
  end
end # SoftLayer