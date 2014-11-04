#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # Each SoftLayer SoftwarePassword instance provides information about
  # a user's password associated with a SoftLayer Software instance.
  #
  # This class roughly corresponds to the entity SoftLayer_Software_Component_Password
  # in the API.
  #
  class SoftwarePassword < ModelBase
    include ::SoftLayer::DynamicAttribute
    
    ##
    # :attr_reader:
    # The date this username/password pair was created.
    sl_attr :created, 'createDate'

    ##
    # :attr_reader:
    # The date of the last modification to this username/password pair.
    sl_attr :modified, 'modifyDate'

    ##
    # :attr_reader:
    # A note string stored for this username/password pair.
    sl_attr :notes

    ##
    # :attr_reader:
    # The password part of the username/password pair.
    sl_attr :password

    ##
    # :attr_reader:
    sl_attr :port

    ##
    # The username part of the username/password pair.
    sl_attr :username

    ##
    # Updates the password for the current software user.
    #
    def password=(password)
      raise ArgumentError, "The new password cannot be nil"   unless password
      raise ArgumentError, "The new password cannot be empty" if password.empty?

      self.service.editObject({ "password" => password.to_s })
      self.refresh_details()
    end

    ##
    # Returns the service for interacting with this software component passowrd through the network API
    #
    def service
      softlayer_client[:Software_Component_Password].object_with_id(self.id)
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
        "mask(SoftLayer_Software_Component_Password)" => [
                                                          'createDate',
                                                          'id',
                                                          'modifyDate',
                                                          'notes',
                                                          'password',
                                                          'port',
                                                          'username'
                                                         ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
