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
    # :attr_reader: created_at
    # The date a disk image was created.
    sl_attr :created_at,    'createDate'

    ##
    # :attr_reader: created
    # The date a disk image was created.
    # DEPRECATION WARNING: This attribute is deprecated in favor of created_at
    # and will be removed in the next major release.
    sl_attr :created,    'createDate'

    ##
    # :attr_reader:
    # A brief description of a virtual disk image.
    sl_attr :description

    ##
    # :attr_reader: modified_at
    # The date a disk image was last modified.
    sl_attr :modified_at,   'modifyDate'

    ##
    # :attr_reader: modified
    # The date a disk image was last modified.
    # DEPRECATION WARNING: This attribute is deprecated in favor of modified_at
    # and will be removed in the next major release.
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
    # Retrieve coalesced disk images associated with this virtual disk image
    # :call-seq:
    #   coalesced_disk_images(force_update=false)
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
    # Retrieve local disk flag associated with virtual disk image
    # :call-seq:
    #   local_disk(force_update=false)
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
    # Retrieve metadata as to whether this disk image is meant for 
    # storage of custom user data supplied with a Cloud Computing Instance order.
    # :call-seq:
    #   metadata(force_update=false)
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
    # Retrieve the references to the software that resides on a disk image.
    # :call-seq:
    #   software(force_update=false)
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
    # Retrieve the original disk image that the current disk image was cloned from.
    # :call-seq:
    #   source_disk_image(force_update=false)
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
    # Retrieve a brief description of a virtual disk image type's function.
    # :call-seq:
    #   type_description(force_update=false)
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
    # Retrieve a virtual disk image type's name.
    # :call-seq:
    #   type_name(force_update=false)
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

    ##
    # Retrieve the virtual disk image with the given server ID from the API
    #
    # The options parameter should contain:
    #
    # <b>+:client+</b> - The client used to connect to the API
    #
    # If no client is given, then the routine will try to use Client.default_client
    # If no client can be found the routine will raise an error.
    #
    # The options may include the following keys
    # * <b>+:object_mask+</b> (string) - A object mask of properties, in addition to the default properties, that you wish to retrieve for the server
    #
    def self.image_with_id(image_id, options = {})
      softlayer_client = options[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      vdi_service = softlayer_client[:Virtual_Disk_Image]
      vdi_service = vdi_service.object_mask(default_object_mask.to_sl_object_mask)

      if options.has_key?(:object_mask)
        vdi_service = vdi_service.object_mask(options[:object_mask])
      end

      image_data = vdi_service.object_with_id(image_id).getObject()

      return VirtualDiskImage.new(softlayer_client, image_data)
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
