module SoftLayer
	class Ticket < SoftLayer::ModelBase
		##
		# Add an update to this ticket.
		#
		def update(body = nil)
			softlayer_client["Ticket"].object_with_id(self.id).edit(@sl_hash, body)
		end

		def softlayer_properties(object_mask = nil)
      service = softlayer_client["Ticket"]

      if(object_mask)
        service = service.object_mask(object_mask)
      else 
        service = service.object_mask(self.class.default_object_mask)
      end

      service.object_with_id(self.id).getObject()
		end

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

		def self.ticket_subjects(softlayer_client)
			@ticket_subjects ||= nil
			if !@ticket_subjects
				@ticket_subjects = softlayer_client['Ticket_Subject'].getAllObjects();
			end
			@ticket_subjects
		end

		def self.ticket_with_id(softlayer_client, ticket_id, options = {})
	      if options.has_key?(:object_mask)
	        object_mask = options[:object_mask]
	      else
	        object_mask = default_object_mask()
	      end

	      ticket_data = softlayer_client["Ticket"].object_with_id(server_id).object_mask(object_mask).getObject()

	      return new(softlayer_client, ticket_data)
	    end

	    def self.create_ticket(softlayer_client, title=nil, body=nil, subject_id=nil, user_id=nil)
	    	if(nil == user_id)
	    		current_user = softlayer_client["Account"].object_mask("id").getCurrentUser()
	    		user_id = current_user["id"]
	    	end

	    	new_ticket = {
	            'subjectId' => subject_id,
	            'contents' => body,
	            'assignedUserId' => user_id,
	            'title' => title
        	}

        	ticket_data = softlayer_client["Ticket"].createStandardTicket(new_ticket, body)
        	return new(softlayer_client, ticket_data)
	    end
	end
end