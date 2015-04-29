#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # Each SoftLayer NetworkMessageDelivery instance provides information about
  # the username/password combination for a specific Network Message Delivery
  # account.
  #
  # This class roughly corresponds to the entity SoftLayer_Network_Message_Delivery
  # in the API.
  #
  class NetworkMessageDelivery < ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader: created
    # The date this username/password pair was created.
    sl_attr :created,  'createDate'

    ##
    # :attr_reader: modified
    # The date of the last modification to this username/password pair.
    sl_attr :modified, 'modifyDate'

    ##
    # :attr_reader:
    # The password part of the username/password pair.
    sl_attr :password

    ##
    # :attr_reader:
    # The username part of the username/password pair.
    sl_attr :username

    ##
    # The message delivery type description of a network message delivery account.
    sl_dynamic_attr :description do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @description == nil
      end

      resource.to_update do
        type = self.service.getType
        type['description']
      end
    end

    ##
    # The message delivery type name of a network message delivery account.
    sl_dynamic_attr :name do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @name == nil
      end

      resource.to_update do
        type = self.service.getType
        type['name']
      end
    end

    ##
    # The vendor name for a network message delivery account.
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
    # Updates the password for the current account password.
    #
    def password=(password)
      raise ArgumentError, "The new password cannot be nil"   unless password
      raise ArgumentError, "The new password cannot be empty" if password.empty?

      self.service.editObject({ "password" => password.to_s })
      self.refresh_details()
    end

    ##
    # Returns the service for interacting with the network message delivery instance
    # through the network API
    #
    def service
      softlayer_client[:Network_Message_Delivery].object_with_id(self.id)
    end

    ##
    # Make an API request to SoftLayer and return the latest properties hash
    # for this object.
    #
    def softlayer_properties(object_mask = nil)
      my_service = self.service

      if(object_mask)
        my_service = my_service.object_mask(object_mask)
      else
        my_service = my_service.object_mask(self.class.default_object_mask)
      end

      my_service.getObject()
    end

    protected

    def self.default_object_mask
      {
        "mask(SoftLayer_Network_Message_Delivery)" => [
                                                       'createDate',
                                                       'id',
                                                       'modifyDate',
                                                       'password',
                                                       'username'
                                                      ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
