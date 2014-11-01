#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # Each SoftLayer VirtualDiskImageSoftware is a record that connects 
  # a computing instance's virtual disk images with software records. 
  #
  # This class roughly corresponds to the entity SoftLayer_Virtual_Disk_Image_Software
  # in the API.
  #
  class VirtualDiskImageSoftware < ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # The manufacturer, name and version of a piece of software.
    #
    def description
      self['softwareDescription']['longDescription']
    end

    ##
    # The name of this specific piece of software.
    #
    def name
      self['softwareDescription']['name']
    end

    ##
    # The password for this specific virtual disk image software instance.
    #
    def passwords
      self['passwords']
    end
    
    protected

    def self.default_object_mask
      {
        "mask(SoftLayer_Virtual_Disk_Image_Software)" => [
                                                          'id',
                                                          'passwords[password,username]',
                                                          'softwareDescription[longDescription,name]'
                                                         ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
