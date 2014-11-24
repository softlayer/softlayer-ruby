#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # Each SoftLayer VirtualDiskImage instance provides information about software
  # installed on a specific piece of hardware.
  #
  # This class roughly corresponds to the entity SoftLayer_Virtual_Disk_Image
  # in the API.
  #
  class VirtualDiskImage < ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader:
    # A disk image's size measured in gigabytes.
    sl_attr :capacity

    ##
    # :attr_reader:
    # A disk image's unique md5 checksum.
    sl_attr :checksum

    ##
    # :attr_reader:
    # The date a disk image was created.
    sl_attr :created,    'createDate'

    ##
    # :attr_reader:
    # A brief description of a virtual disk image.
    sl_attr :description

    ##
    # :attr_reader:
    # The date a disk image was last modified.
    sl_attr :modified,   'modifyDate'

    ##
    # :attr_reader:
    # A descriptive name used to identify a disk image to a user.
    sl_attr :name

    ##
    # :attr_reader:
    # The unit of storage in which the size of the image is measured.
    # Defaults to "GB" for gigabytes.
    sl_attr :units

    ##
    # :attr_reader:
    # A disk image's unique ID on a virtualization platform.
    sl_attr :uuid

    ##
    # Returns coalesced disk images associated with this virtual disk image
    sl_dynamic_attr :coalesced_disk_images do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @coalesced_disk_images == nil
      end

      resource.to_update do
        coalesced_disk_images = self.service.getCoalescedDiskImages
        coalesced_disk_images.collect { |coalesced_disk_image| VirtualDiskImage.new(softlayer_client, coalesced_disk_image) }
      end
    end
    
    ##
    # Returns local disk flag associated with virtual disk image
    sl_dynamic_attr :local_disk do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @local_disk == nil
      end

      resource.to_update do
        self.service.getLocalDiskFlag
      end
    end

    ##
    # Whether this disk image is meant for storage of custom user data
    # supplied with a Cloud Computing Instance order.
    sl_dynamic_attr :metadata do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @metadata == nil
      end

      resource.to_update do
        self.service.getMetadataFlag
      end
    end

    ##
    # References to the software that resides on a disk image.
    sl_dynamic_attr :software do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @software == nil
      end

      resource.to_update do
        software_references = self.service.object_mask(VirtualDiskImageSoftware.default_object_mask).getSoftwareReferences
        software_references.collect { |software| VirtualDiskImageSoftware.new(softlayer_client, software) unless software.empty? }.compact
      end
    end

    ##
    # The original disk image that the current disk image was cloned from.
    sl_dynamic_attr :source_disk_image do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @source_disk_image == nil
      end

      resource.to_update do
        source_disk_image = self.service.object_mask(VirtualDiskImage.default_object_mask).getSourceDiskImage
        VirtualDiskImage.new(softlayer_client, source_disk_image) unless source_disk_image.empty?
      end
    end

    ##
    # A brief description of a virtual disk image type's function.
    sl_dynamic_attr :type_description do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @type_description == nil
      end

      resource.to_update do
        type = self.service.getType
        type['description']
      end
    end

    ##
    # A virtual disk image type's name.
    sl_dynamic_attr :type_name do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @type_name == nil
      end

      resource.to_update do
        type = self.service.getType
        type['name']
      end
    end

    ##
    # Returns the service for interacting with this virtual disk image through the network API
    #
    def service
      softlayer_client[:Virtual_Disk_Image].object_with_id(self.id)
    end

    protected

    def self.default_object_mask
      {
        "mask(SoftLayer_Virtual_Disk_Image)" => [
                                                 'capacity',
                                                 'checksum',
                                                 'createDate',
                                                 'description',
                                                 'id',
                                                 'modifyDate',
                                                 'name',
                                                 'units',
                                                 'uuid'
                                                ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
