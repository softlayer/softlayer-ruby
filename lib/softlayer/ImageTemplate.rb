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
      self.service.editObject({ "name" => new_name.to_s})
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

    ##
    # Changes the notes on an template to be the given strings
    def notes=(new_notes)
      # it is not a typo that this sets the "note" property.  The 
      # property in the network api is "note", the model exposes it as
      # 'notes' for self-consistency
      self.service.editObject({ "note" => new_notes.to_s})
    end

    ##
    # Returns an array of the tags set on the image
    def tags
      return self["tagReferences"].collect{ |tag_reference| tag_reference["tag"]["name"] }
    end

    ##
    # Sets the tags on the template.  Note: a pre-existing tag will be 
    # removed from the template if it does not appear in the array given.
    # The list of tags must be comprehensive.
    def tags=(tags_array)
      as_strings = tags_array.collect { |tag| tag.to_s }      
      self.service.setTags(as_strings.join(','))
    end

    ##
    # Returns the an array containing the datacenters where this image is available.
    def datacenters
      self["datacenters"].collect{ |datacenter_data| SoftLayer::Datacenter.datacenter_named(datacenter_data["name"])}
    end

    ##
    # Accepts an array of datacenters (instances of SoftLayer::Datacenter) where this
    # image should be made available. The call will kick off transactions to make
    # the image available in the given datacenters.  These transactions can take
    # some time to complete.
    #
    # Note that the template will be REMOVED from any datacenter that does not
    # appear in this array!  The list given must be comprehensive.
    def datacenters=(datacenters_array)
      datacenter_data = datacenters_array.collect do |datacenter| 
        raise "Image templates cannot be copied to the data center #{datacenter.name}" unless datacenter.available_for_image_templates?
        { "id" => datacenter.id }
      end

      self.service.setAvailableLocations(datacenter_data.compact)
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
    # Creates a transaction to delete the image template and
    # all the disk images associated with it.
    #
    # This is a final action and cannot be undone.
    # the transaction will proceed immediately.
    #
    # Call it with extreme care!
    def delete!
      self.service.deleteObject
    end
    
    ##
    # Wait until transactions related to the image template are finished
    #
    # A template is not ready until all the transactions on the template
    # itself, and all its children are complete.
    #
    # At each trial, the routine will yield to a block if one is given
    # The block is passed one parameter, a boolean flag indicating
    # whether or not the image template is 'ready'. Interim invocations
    # of the block should receive +false+, the final invocation should
    # receieve +true+
    #
    def wait_until_ready(max_trials, seconds_between_tries = 2)
      # pessimistically assume the server is not ready
      num_trials = 0
      begin
        self.refresh_details()

        parent_ready = !(has_sl_property? :transactionId) || (self[:transactionId] == "")
        children_ready = (nil == self["children"].find { |child| child["transactionId"] != "" })

        ready = parent_ready && children_ready        
        yield ready if block_given?

        num_trials = num_trials + 1
        sleep(seconds_between_tries) if !ready && (num_trials <= max_trials)
      end until ready || (num_trials >= max_trials)

      ready
    end
    
    # ModelBase protocol methods
    def service
      softlayer_client['Virtual_Guest_Block_Device_Template_Group'].object_with_id(self.id)
    end
    
    def softlayer_properties(object_mask = nil)
      self.service.object_mask(self.class.default_object_mask).getObject
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
    def self.find_private_templates(options_hash = {})
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
            'value' => options_hash[:tags].collect{ |tag_value| tag_value.to_s }
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
    def self.find_public_templates(options_hash = {})
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
            'value' => options_hash[:tags].collect{ |tag_value| tag_value.to_s }
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
    def self.template_with_id(id, options_hash = {})
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

    def self.default_object_mask
      return "mask[id,name,note,globalIdentifier,datacenters,blockDevices,tagReferences,publicFlag,flexImageFlag,transactionId,children.transactionId]"
    end
  end
end