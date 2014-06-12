#
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

module SoftLayer
	class Ticket < SoftLayer::ModelBase

    ##
    # :attr_reader: title
    # The title is an identifying string set when the ticket is created
    sl_attr :title

    ##
    # :attr_reader: subject
    # The ticket system maintains a fixed set of subjects for tickets that are used to ensure tickets make it to the right folks quickly
    sl_attr :subject

    ##
    # Returns true if the ticket has "unread" updates
    def has_updates?
      self["newUpdatesFlag"] != 0
    end

    ##
    # Returns true if the ticket is a server admin ticket
    def server_admin_ticket?
      self["serverAdministrationFlag"] != 0
    end

		##
		# Add an update to this ticket.
		#
		def update(body = nil)
			self.service.edit(self.softlayer_hash, body)
		end
    
    ## 
    # Override of service from ModelBase. Returns the SoftLayer_Ticket service
    # set up to talk to the ticket with my ID.
    def service
      return softlayer_client["Ticket"].object_with_id(self.id)
    end

    ##
    # Override from model base. Requests new details about the ticket
    # from the server.
		def softlayer_properties(object_mask = nil)
      my_service = self.service

      if(object_mask)
        my_service = service.object_mask(object_mask)
      else
        my_service = service.object_mask(self.class.default_object_mask.to_sl_object_mask)
      end

      my_service.getObject()
		end

    ##
    # Returns the default object mask,as a hash, that is used when
    # retrieving ticket information from the SoftLayer server.
		def self.default_object_mask
      {
        "mask" => [
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
      }
		end

    ##
    # Queries the SoftLayer API to retrieve a list of the valid
    # ticket subjects.
		def self.ticket_subjects(softlayer_client)
			@ticket_subjects ||= nil
			if !@ticket_subjects
				@ticket_subjects = softlayer_client['Ticket_Subject'].getAllObjects();
			end
			@ticket_subjects
		end

    ##
    # Find the ticket with the given ID and return it
		def self.ticket_with_id(softlayer_client, ticket_id, options = {})
      if options.has_key?(:object_mask)
        object_mask = options[:object_mask]
      else
        object_mask = default_object_mask.to_sl_object_mask
      end

      ticket_data = softlayer_client["Ticket"].object_with_id(server_id).object_mask(object_mask).getObject()

      return new(softlayer_client, ticket_data)
    end

    ##
    # Create and submit a new support Ticket to SoftLayer.
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