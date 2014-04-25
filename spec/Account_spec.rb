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

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

require 'spec_helper'

describe SoftLayer::Account do
	it "should exist" do
		SoftLayer::Account.should_not be_nil
	end

  it "should return its initialization id as the account_id" do
    test_account = SoftLayer::Account.new(nil, "id" => "232279", "firstName" => "kangaroo")
    test_account.account_id.should eq("232279")

    another_test_acct = SoftLayer::Account.new(nil, :id => "232279", "firstName" => "kangaroo")
    test_account.account_id.should eq("232279")
  end

  it "should allow the user to get the default account for a service" do
    test_client = double("mockClient")
    allow(test_client).to receive(:[]) do |service_name|
      service_name.should == "Account"

      test_service = double("mockService")
      allow(test_service).to receive(:getObject) do
        { "id" => "232279", "firstName" => "kangaroo" }
      end

      test_service
    end

    test_account = SoftLayer::Account.account_for_client(test_client)
    test_account.softlayer_client.should eq(test_client)
    test_account.account_id.should eq("232279")
    test_account.id.should eq("232279")
    test_account.firstName.should eq("kangaroo")
  end

  describe "relationship to servers" do
    before do
      fixture_account_data = fixture_from_json("test_account")
      fixture_bare_metal_data = fixture_from_json("test_bare_metal.json")
      fixture_virtual_server_data = fixture_from_json("test_virtual_servers")

      @mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "fake_api_key")
      allow(@mock_client).to receive(:[]) do |service_name|
        service_name.should == "Account"

        if !@mock_service
          @mock_service = SoftLayer::Service.new("SoftLayer_Account", :client => @mock_client)
          allow(@mock_service).to receive(:getObject).and_return(fixture_account_data)

          expect(@mock_service).to receive(:getHardware).and_return(fixture_bare_metal_data)
          expect(@mock_service).to receive(:getVirtualGuests).and_return(fixture_virtual_server_data)
          allow(@mock_service).to receive(:object_mask).and_return(@mock_service)

          # if we've stubbed everything out correctly... we shouldn't actually be calling the API
          expect(@mock_service).to_not receive(:call_softlayer_api_with_params)
        end

        @mock_service
      end
    end

    it "should respond to a request for servers" do
      test_account = SoftLayer::Account.account_for_client(@mock_client)

      test_account.should respond_to(:servers)
      test_account.should_not respond_to(:servers=)

      servers = test_account.servers
      servers.length.should eq(6)
    end
  end

  describe "fetching tickets" do
    before do
      fixture_account_data = fixture_from_json("test_account")
      fixture_open_tickets = fixture_from_json("test_tickets")
      fixture_closed_tickets = fixture_from_json("test_tickets.json")

      @mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "fake_api_key")
      allow(@mock_client).to receive(:[]) do |service_name|
        service_name.should == "Account"

        if !@mock_service

          @mock_service = SoftLayer::Service.new("SoftLayer_Account", :client => @mock_client)
          allow(@mock_service).to receive(:getObject).and_return(fixture_account_data)
          allow(@mock_service).to receive(:object_mask).and_return(@mock_service)
          allow(@mock_service).to receive(:call_softlayer_api_with_params)

          expect(@mock_service).to receive(:getOpenTickets).and_return(fixture_open_tickets)
          expect(@mock_service).to receive(:getTicketsClosedInTheLastThreeDays).and_return(fixture_closed_tickets)

          # if we've stubbed everything out correctly... we shouldn't actually be calling the API
          expect(@mock_service).to_not receive(:call_softlayer_api_with_params)
        end

        @mock_service
      end
    end

    it "responds to a tickets request" do
      test_account = SoftLayer::Account.account_for_client(@mock_client)
      test_account.should respond_to(:tickets)
      test_account.should_not respond_to(:tickets=)

      tickets = test_account.tickets
    end
  end

end