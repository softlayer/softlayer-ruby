#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # Each SoftLayer UserCustomerExternalBinding instance provides information
  # for a single user customer's external binding.
  #
  # This class roughly corresponds to the entity SoftLayer_User_Customer_External_Binding
  # in the API.
  #
  class UserCustomerExternalBinding < ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader:
    # The flag that determines whether the external binding is active will be
    # used for authentication or not.
    sl_attr :active

    ##
    # :attr_reader: created
    # The date that the external authentication binding was created.
    sl_attr :created, 'createDate'

    ##
    # :attr_reader:
    # The password used to authenticate the external id at an external
    # authentication source.
    sl_attr :password

    ##
    # Retrieve an optional note for identifying the external binding.
    # :call-seq:
    #   note(force_update=false)
    sl_dynamic_attr :note do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @note == nil
      end

      resource.to_update do
        self.service.getNote
      end
    end

    ##
    # Retrieve the user friendly name of a type of external authentication binding.
    # :call-seq:
    #   type(force_update=false)
    sl_dynamic_attr :type do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @type == nil
      end

      resource.to_update do
        type = self.service.getType
        type['name']
      end
    end

    ##
    # Retrieve the user friendly name of an external binding vendor.
    # :call-seq:
    #   vendor(force_update=false)
    sl_dynamic_attr :vendor do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @vendor == nil
      end

      resource.to_update do
        vendor = self.service.getVendor
        vendor['name']
      end
    end

    ##
    # Returns the service for interacting with this user customer external binding
    # through the network API
    #
    def service
      softlayer_client[:User_Customer_External_Binding].object_with_id(self.id)
    end

    protected

    def self.default_object_mask
      {
        "mask(SoftLayer_User_Customer_External_Binding)" => [
                                                             'active',
                                                             'createDate',
                                                             'id',
                                                             'password'
                                                            ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
