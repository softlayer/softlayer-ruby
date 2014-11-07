#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # Each SoftLayer NetworkStorageCredential instance provides information
  # on a username/password credential combination used to access a specific
  # Network Storage.
  #
  # This class roughly corresponds to the entity SoftLayer_Network_Storage_Credential
  # in the API.
  #
  class NetworkStorageCredential < ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader:
    # This is the data that the record was created in the table.
    sl_attr :created,  'createDate'

    ##
    # :attr_reader:
    # This is the date that the record was last updated in the table.
    sl_attr :modified, 'modifyDate'

    ##
    # :attr_reader:
    # This is the password associated with the volume.
    sl_attr :password

    ##
    # :attr_reader:
    # This is the username associated with the volume.
    sl_attr :username
 
    ##
    # Returns a description of the Network Storage Credential type
    #
    def description
      self['type']['description']
    end

    ##
    # Returns the name of the Network Storage Credential type
    #
    def name
      self['type']['name']
    end

    protected

    def self.default_object_mask
      {
        "mask(SoftLayer_Network_Storage_Credential)" => [
                                                         'createDate',
                                                         'id',
                                                         'modifyDate',
                                                         'password',
                                                         'type.description',
                                                         'type.name',
                                                         'username'
                                                        ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
