#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  class Ticket < SoftLayer::ModelBase

    ##
    # :attr_reader:
    # The title is an identifying string set when the ticket is created
    sl_attr :title

    ##
    # :attr_reader:
    # The ticket system maintains a fixed set of subjects for tickets that are used to ensure tickets make it to the right folks quickly
    sl_attr :subject

    ##
    # :attr_reader: last_edited_at
    # The date the ticket was last updated.
    sl_attr :last_edited_at, 'lastEditDate'

    ##
    # :attr_reader:
    # The date the ticket was last updated.
    #
    # DEPRECATION WARNING: This attribute is deprecated in favor of last_edited_at
    # and will be removed in the next major release.
    sl_attr :lastEditDate

    ##
    # Returns true if the ticket has "unread" updates
    def has_updates?
      self['newUpdatesFlag']
    end

    ##
    # Returns true if the ticket is a server admin ticket
    def server_admin_ticket?
      # note that serverAdministrationFlag comes from the server as an Integer (0, or 1)
      self['serverAdministrationFlag'] != 0
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
      return softlayer_client[:Ticket].object_with_id(self.id)
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
          'newUpdatesFlag',             # This comes in from the server as a Boolean value
          'awaitingUserResponseFlag',   # This comes in from the server as a Boolean value
          'serverAdministrationFlag',   # This comes in from the server as an integer :-(
        ]
      }.to_sl_object_mask
    end

    ##
    # Queries the SoftLayer API to retrieve a list of the valid
    # ticket subjects.
    def self.ticket_subjects(client = nil)
      @ticket_subjects ||= nil

      if !@ticket_subjects
        softlayer_client = client || Client.default_client
        raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

        @ticket_subjects = softlayer_client[:Ticket_Subject].getAllObjects();
      end

      @ticket_subjects
    end

    ##
    # Find the ticket with the given ID and return it
    #
    # Options should contain:
    #
    # <b>+:client+</b> - the client in which to search for the ticket
    #
    # If a client is not provided then the routine will search Client::default_client
    # If Client::default_client is also nil the routine will raise an error.
    #
    # Additionally you may provide options related to the request itself:
    # * <b>*:object_mask*</b> (string) - The object mask of properties you wish to receive for the items returned.
    #                                    If not provided, the result will use the default object mask
    def self.ticket_with_id(ticket_id, options = {})
      softlayer_client = options[:client] || Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      if options.has_key?(:object_mask)
        object_mask = options[:object_mask]
      else
        object_mask = default_object_mask.to_sl_object_mask
      end

      ticket_data = softlayer_client[:Ticket].object_with_id(ticket_id).object_mask(object_mask).getObject()

      return Ticket.new(softlayer_client, ticket_data)
    end

    ##
    # Create and submit a new support Ticket to SoftLayer.
    #
    # The options parameter should contain:
    #
    # <b>+:client+</b> - The client used to connect to the API
    #
    # If no client is given, then the routine will try to use Client.default_client
    # If no client can be found the routine will raise an error.
    #
    # The options should also contain:
    #
    # * <b>+:title+</b> (String) - The user provided title for the ticket.
    # * <b>+:body+</b> (String) - The content of the ticket
    # * <b>+:subject_id+</b> (Int) - The id of a subject to use for the ticket.  A list of ticket subjects can be returned by SoftLayer::Ticket.ticket_subjects
    # * <b>+:assigned_user_id+</b> (Int) - The id of a user to whom the ticket should be assigned
    def self.create_standard_ticket(options = {})
      softlayer_client = options[:client] || SoftLayer::Client.default_client
      raise "#{__method__} requires a client but none was given and Client::default_client is not set" if !softlayer_client

      title = options[:title]
      body = options[:body]
      subject_id = options[:subject_id]
      assigned_user_id = options[:assigned_user_id]

      if(nil == assigned_user_id)
        current_user = softlayer_client[:Account].object_mask("id").getCurrentUser()
        assigned_user_id = current_user['id']
      end

      new_ticket = {
        'subjectId' => subject_id,
        'contents' => body,
        'assignedUserId' => assigned_user_id,
        'title' => title
      }

      ticket_data = softlayer_client[:Ticket].createStandardTicket(new_ticket, body)
      return new(softlayer_client, ticket_data)
    end
  end
end
