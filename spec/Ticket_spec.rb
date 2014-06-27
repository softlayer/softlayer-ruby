#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++



$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

require 'spec_helper'

describe SoftLayer::Ticket do
  before (:each) do
    SoftLayer::Ticket.instance_eval { @ticket_subjects = nil }
  end

  it "fetches a list of open tickets" do
    mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "fake_api_key")
    account_service = mock_client["Account"]

    expect(account_service).to receive(:call_softlayer_api_with_params).with(:getOpenTickets, instance_of(SoftLayer::APIParameterFilter),[]) do
      fixture_from_json("test_tickets")
    end

    SoftLayer::Ticket.open_tickets(:client => mock_client)
  end

	it "retrieves ticket subjects from API once" do
    fakeTicketSubjects = fixture_from_json("ticket_subjects")

	  mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key=> 'fakekey')
    allow(mock_client).to receive(:[]) do |service_name|
      expect(service_name).to eq "Ticket_Subject"

      mock_service = SoftLayer::Service.new("SoftLayer_Ticket_Subject", :client => mock_client)
      expect(mock_service).to receive(:getAllObjects).once.and_return(fakeTicketSubjects)
      expect(mock_service).to_not receive(:call_softlayer_api_with_params)

      mock_service
    end

    expect(SoftLayer::Ticket.ticket_subjects(mock_client)).to be(fakeTicketSubjects)

    # call for the subjects again which should NOT re-request them from the client
    # (so :getAllObjects on the service should not be called again)
    expect(SoftLayer::Ticket.ticket_subjects(mock_client)).to be(fakeTicketSubjects)
	end

  it "raises an error if you try to get ticket subjects with no client" do
    SoftLayer::Client.default_client = nil
    expect {SoftLayer::Ticket.ticket_subjects() }.to raise_error
  end

  it "identifies itself with the ticket service" do
    fake_ticket_data = fixture_from_json("test_tickets").first

	  mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key=> 'fakekey')
    allow(mock_client).to receive(:[]) do |service_name|
      expect(service_name).to eq "Ticket"
      mock_service = SoftLayer::Service.new("SoftLayer_Ticket", :client => mock_client)

      # mock out call_softlayer_api_with_params so the service doesn't actually try to
      # communicate with the api endpoint
      allow(mock_service).to receive(:call_softlayer_api_with_params)

      mock_service
    end

    fake_ticket = SoftLayer::Ticket.new(mock_client, fake_ticket_data)
    ticket_service = fake_ticket.service
    expect(ticket_service.server_object_id).to eq(12345)
    expect(ticket_service.target.service_name).to eq "SoftLayer_Ticket"
  end
end