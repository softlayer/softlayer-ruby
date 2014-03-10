module SoftLayer
	class Ticket < SoftLayer::ModelBase
		def self.default_object_mask
			[
				'id',							# This is an internal ticket ID, not the one usually seen in the portal
				'serviceProvider',
				'serviceProviderResourceId', 	# This is the ticket ID usually seen in the portal
				'title',
				'subject',
				{'assignedUser' => ['username', 'firstName', 'lastName'] },
				'status.id',
				'createDate',
				'lastEditDate',
				'newUpdatesFlag',
				'awaitingUserResponseFlag',
				'serverAdministrationFlag',
			]
		end

		def self.ticket_subjects!(softlayer_client)
			@ticket_subjects ||= nil
			if !@ticket_subjects
				@ticket_subjects = softlayer_client['Ticket_Subject'].getAllObjects();
			end
			@ticket_subjects
		end

		def self.ticket_with_id!(softlayer_client, ticket_id, options = {})
	      if options.has_key?(:object_mask)
	        object_mask = options[:object_mask]
	      else
	        object_mask = default_object_mask()        
	      end

	      ticket_data = softlayer_client["Ticket"].object_with_id(server_id).object_mask(object_mask).getObject()

	      return new(softlayer_client, ticket_data)
	    end
	end
end