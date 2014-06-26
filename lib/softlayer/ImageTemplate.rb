#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++


module SoftLayer
  ##
  # A Virtual Server Image Template.
  #
  # This class rougly corresponds to the unwieldily named
  # +SoftLayer_Virtual_Guest_Block_Device_Template_Group+
  # service:
  #
  # http://sldn.softlayer.com/reference/services/SoftLayer_Virtual_Guest_Block_Device_Template_Group
  #
  #
  class ImageTemplate < SoftLayer::ModelBase
    ##
    # :attr_reader:
    # The 'friendly name' given to the template when it was created
    sl_attr :name

    ##
    # :attr_reader:
    # The notes, if any, that are attached to the template. Can be nil.
    sl_attr :notes, "note"

    ##
    # :attr_reader:
    # The universally unique identifier (if any) for the template. Can be nil.
    sl_attr :global_id, 'globalIdentifier'

    # Change the name of the template
    def rename!(new_name)
    end

    ##
    # true if the image template is a flex image
    # Note that the publicFlag property comes back as an integer (0 or 1)
    def public?
      self["publicFlag"] != 0
    end

    ##
    # true if the image template is a flex image
    # Note that the flexImageFlag property comes back as a boolean
    def flex_image?
      !!self["flexImageFlag"]
    end

    def notes=
    end

    # Get and set an array of the tags on the image
    def tags
    end

    def tags=
    end

    ##
    # Works with an array of data center names (short names)
    # where the image template is available
    #
    # Should this be datacenters and "add_datacenters, remove_datacenters"
    def datacenters
    end

    def datacenters=
    end

    ##
    # Wait until transactions related to the image template are finsihed
    def wait_until_ready(max_trials, seconds_between_tries = 2)
    end

    ##
    # Works with an array of account IDs (or should use master user names i.e. "SL232279" )
    # that the image template is shared with
    #
    # Should this be datacenters an "share_with_accounts, stop_sharing_with_accounts"
    def shared_with_accounts
    end

    def shared_with_accounts=
    end

    ##
    # Retrieve a list of the private image templates from the account.
    #
    # The options parameter should contain:
    #
    # <b>+:client+</b> - The client used to connect to the API
    #
    # If no client is given, then the routine will try to use Client.default_client.
    # If no client can be found the routine will raise an error.
    #
    # Additional options that may be provided:
    # * <b>+:name+</b> (string) - Return templates with the given name
    # * <b>+:global_id+</b> (string) - Return templates with the given global identfier
    def ImageTemplate.find_private_templates(options_hash = {})
      softlayer_client = options_hash[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      if(options_hash.has_key? :object_filter)
        object_filter = options_hash[:object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        object_filter = ObjectFilter.new()
      end

      option_to_filter_path = {
        :name => "privateBlockDeviceTemplateGroups.name",
        :global_id => "privateBlockDeviceTemplateGroups.globalIdentifier",
      }

      # For each of the options in the option_to_filter_path map, if the options hash includes
      # that particular option, add a clause to the object filter that filters for the matching
      # value
      option_to_filter_path.each do |option, filter_path|
        object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option])} if options_hash[option]
      end

      # Tags get a much more complex object filter operation so we handle them separately
      if options_hash.has_key?(:tags)
        object_filter.set_criteria_for_key_path("privateBlockDeviceTemplateGroups.tagReferences.tag.name", {
          'operation' => 'in',
          'options' => [{
            'name' => 'data',
            'value' => options_hash[:tags]
            }]
          } );
      end

      account_service = softlayer_client['Account']
      account_service = account_service.object_filter(object_filter) unless object_filter.empty?
      account_service = account_service.object_mask(default_object_mask)

      if options_hash.has_key? :object_mask
        account_service = account_service.object_mask(options_hash[:object_mask])
      end

      if options_hash.has_key?(:result_limit)
        offset = options[:result_limit][:offset]
        limit = options[:result_limit][:limit]

        account_service = account_service.result_limit(offset, limit)
      end

      templates_data = account_service.getPrivateBlockDeviceTemplateGroups
      templates_data.collect { |template_data| new(softlayer_client, template_data) }
    end

    ##
    # Retrieve a list of public image templates
    #
    # The options parameter should contain:
    #
    # <b>+:client+</b> - The client used to connect to the API
    #
    # If no client is given, then the routine will try to use Client.default_client
    # If no client can be found the routine will raise an error.
    #
    # Additional options that may be provided:
    # * <b>+:name+</b> (string) - Return templates with the given name
    # * <b>+:global_id+</b> (string) - Return templates with the given global identfier
    def ImageTemplate.find_public_templates(options_hash = {})
      softlayer_client = options_hash[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      if(options_hash.has_key? :object_filter)
        object_filter = options_hash[:object_filter]
        raise "Expected an instance of SoftLayer::ObjectFilter" unless object_filter.kind_of?(SoftLayer::ObjectFilter)
      else
        object_filter = ObjectFilter.new()
      end

      option_to_filter_path = {
        :name => "publicImages.name",
        :global_id => "publicImages.globalIdentifier",
      }

      # For each of the options in the option_to_filter_path map, if the options hash includes
      # that particular option, add a clause to the object filter that filters for the matching
      # value
      option_to_filter_path.each do |option, filter_path|
        object_filter.modify { |filter| filter.accept(filter_path).when_it is(options_hash[option])} if options_hash[option]
      end

      # Tags get a much more complex object filter operation so we handle them separately
      if options_hash.has_key?(:tags)
        object_filter.set_criteria_for_key_path("publicImages.tagReferences.tag.name", {
          'operation' => 'in',
          'options' => [{
            'name' => 'data',
            'value' => options_hash[:tags]
            }]
          } );
      end

      template_service = softlayer_client['Virtual_Guest_Block_Device_Template_Group']
      template_service = template_service.object_filter(object_filter) unless object_filter.empty?
      template_service = template_service.object_mask(default_object_mask)

      if options_hash.has_key? :object_mask
        template_service = template_service.object_mask(options_hash[:object_mask])
      end

      if options_hash.has_key?(:result_limit)
        offset = options[:result_limit][:offset]
        limit = options[:result_limit][:limit]

        template_service = template_service.result_limit(offset, limit)
      end

      templates_data = template_service.getPublicImages
      templates_data.collect { |template_data| new(softlayer_client, template_data) }
    end

    ##
    # Retrive the Image Template with the given ID
    # (Note! This is the service ID, not the globalIdentifier!)
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
    def ImageTemplate.template_with_id(id, options_hash = {})
      softlayer_client = options_hash[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      service = softlayer_client['Virtual_Guest_Block_Device_Template_Group'].object_with_id(id)
      service.object_mask(default_object_mask)

      if options_hash.has_key? :object_mask
        service = service.object_mask(options_hash[:object_mask])
      end

      template_data = service.getObject
      new(softlayer_client, template_data)
    end

    protected

    def ImageTemplate.default_object_mask
      return "mask[id,name,note,globalIdentifier,datacenters,blockDevices,tagReferences,publicFlag,flexImageFlag]"
    end
  end
end