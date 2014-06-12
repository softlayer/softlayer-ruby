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
    
    softlayer_attr :title
    softlayer_attr :subject

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
			softlayer_client["Ticket"].object_with_id(self.id).edit(self.softlayer_hash, body)
		end

		def softlayer_properties(object_mask = nil)
      service = softlayer_client["Ticket"]

      if(object_mask)
        service = service.object_mask(object_mask)
      else
        service = service.object_mask(self.class.default_object_mask.to_sl_object_mask)
      end

      service.object_with_id(self.id).getObject()
		end

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
        object_mask = default_object_mask.to_sl_object_mask
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