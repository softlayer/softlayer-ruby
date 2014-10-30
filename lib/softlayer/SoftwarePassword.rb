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
    # Returns the service for interacting with this software component passowrd through the network API
    #
    def service
      softlayer_client[:Software_Component_Password].object_with_id(self.id)
    end

    protected

    def self.default_object_mask(root)
      "#{root}[createDate,id,modifyDate,notes,password,port,username]"
    end
  end
end #SoftLayer
