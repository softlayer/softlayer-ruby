#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # Each SoftLayer AccountPassword instance provides information about
  # a user's password associated with a SoftLayer Account instance.
  #
  # This class roughly corresponds to the entity SoftLayer_Account_Password
  # in the API.
  #
  class AccountPassword < ModelBase
    include ::SoftLayer::DynamicAttribute
    
    ##
    # :attr_reader:
    # A simple description of a username/password combination.
    sl_attr :notes

    ##
    # :attr_reader:
    # The password portion of a username/password combination.
    sl_attr :password

    ##
    # :attr_reader:
    # The username portion of a username/password combination.
    sl_attr :username

    ##
    # A description of the use for the account username/password combination.
    sl_dynamic_attr :description do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @description == nil
      end

      resource.to_update do
        description = self.service.object_mask("mask[type.description]").getObject
        description['type']['description']
      end
    end

    ##
    # Returns the service for interacting with this account password through the network API
    #
    def service
      softlayer_client[:Account_Password].object_with_id(self.id)
    end

    protected

    def self.default_object_mask(root)
      "#{root}[accountId,id,notes,password,type.description,typeId,username]"
    end
  end
end #SoftLayer
