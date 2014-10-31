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
    # :attr_reader:
    # The date that the external authentication binding was created.
    sl_attr :created, 'createDate'

    ##
    # :attr_reader:
    # The password used to authenticate the external id at an external
    # authentication source.
    sl_attr :password

    ##
    # :attr_reader:
    # An optional note for identifying the external binding.
    sl_attr :note

    ##
    # Returns the service for interacting with this user customer extnerla binding
    # through the network API
    #
    def service
      softlayer_client[:User_Customer_External_Binding].object_with_id(self.id)
    end

    ##
    # The user friendly name of a type of external authentication binding.
    #
    def type
      self['type']['name']
    end

    ##
    # The user friendly name of an external binding vendor.
    #
    def vendor
      self['vendor']['name']
    end

    protected

    def self.default_object_mask
      {
        "mask(SoftLayer_User_Customer_External_Binding)" => [
                                                             'active',
                                                             'createDate',
                                                             'id',
                                                             'password',
                                                             'note',
                                                             'type.name',
                                                             'vendor.name'
                                                            ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
