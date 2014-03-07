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
require 'json'

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

      puts "returning test service ${test_service}"
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
      FAKE_ACCOUNT_DATA = JSON.parse(File.read(File.join(File.dirname(__FILE__), "test_account.json")))
      FAKE_BARE_METAL_DATA = JSON.parse(File.read(File.join(File.dirname(__FILE__), "test_bare_metal.json")))
      FAKE_VIRTUAL_SERVER_DATA = JSON.parse(File.read(File.join(File.dirname(__FILE__), "test_virtual_servers.json")))

      @mock_client = double("mockClient")
      allow(@mock_client).to receive(:[]) do |service_name|
        service_name.should == "Account"

        mock_service = SoftLayer::Service.new("SoftLayer_Account", :username => "fakeuser", :api_key => "fake_api_key", :endpoint_url => "don'teventhinkaboutit")
        mock_service.stub(:getObject).and_return(FAKE_ACCOUNT_DATA)
        mock_service.stub(:getHardware).and_return(FAKE_BARE_METAL_DATA)
        mock_service.stub(:getVirtualGuests).and_return(FAKE_VIRTUAL_SERVER_DATA)
        mock_service.stub(:object_mask).and_return(mock_service)
        mock_service.stub(:call_softlayer_api_with_params)

        mock_service
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
end