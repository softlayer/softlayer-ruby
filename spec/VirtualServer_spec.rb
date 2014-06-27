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

require 'shared_server'

describe SoftLayer::VirtualServer do
	let(:sample_server) {
		mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "DEADBEEFBADF00D")
		allow(mock_client).to receive(:[]) do |service_name|
			service = mock_client.service_named(service_name)
			allow(service).to receive(:call_softlayer_api_with_params)
			service
		end

		SoftLayer::VirtualServer.new(mock_client, { "id" => 12345 })
	}

  it "identifies itself with the SoftLayer_Virtual_Guest service" do
    service = sample_server.service
    expect(service.server_object_id).to eq(12345)
    expect(service.target.service_name).to eq "SoftLayer_Virtual_Guest"
  end

  it "implements softlayer properties inherited from Server" do
		mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "DEADBEEFBADF00D")

    test_servers = fixture_from_json('test_virtual_servers')
    test_server = SoftLayer::VirtualServer.new(mock_client,test_servers.first)

    expect(test_server.hostname).to eq("test-server-1")
    expect(test_server.domain).to eq("softlayer-api-test.rb")
    expect(test_server.fullyQualifiedDomainName).to eq("test-server-1.softlayer-api-test.rb")
    expect(test_server.datacenter).to eq({"id"=>17936, "longName"=>"Dallas 6", "name"=>"dal06"})
    expect(test_server.primary_public_ip).to eq("198.51.100.121")
    expect(test_server.primary_private_ip).to eq("203.0.113.82")
    expect(test_server.notes).to eq("These are test notes")
  end

	it_behaves_like "server with port speed" do
		let (:server) { sample_server }
	end

  it_behaves_like "server with mutable hostname" do
		let (:server) { sample_server }
  end
  
  describe "component upgrades" do
    let(:mock_client) do
  		mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "DEADBEEFBADF00D")
      virtual_guest_service = mock_client[:Virtual_Guest]
    
      allow(virtual_guest_service).to receive(:call_softlayer_api_with_params) do |api_method, parameters, api_arguments|
        api_return = nil

        case api_method
        when :getUpgradeItemPrices
          api_return = fixture_from_json('virtual_server_upgrade_options')
        else
          fail "Unexpected call to the SoftLayer_Virtual_Guest service"
        end
        
        api_return
      end

      mock_client
    end

    it "retrieves the item upgrades for a server from the API once" do
      fake_virtual_server = SoftLayer::VirtualServer.new(mock_client, {"id" => 12345})
      expect(fake_virtual_server.upgrade_options).to eq fixture_from_json('virtual_server_upgrade_options')

      # once we've retrieve the options once, we shouldn't be calling back into the service to get them again
      expect(mock_client[:Virtual_Guest]).to_not receive(:call_softlayer_api_with_params)
      fake_virtual_server.upgrade_options
    end

    describe "individual component upgrades" do
      before(:each) do
        expect(mock_client[:Product_Order]).to receive(:call_softlayer_api_with_params) do |api_method, parameters, api_arguments|
          expect(api_method).to be(:placeOrder)
          expect(parameters).to be_nil
          expect(api_method).to_not be_empty
        end
      end
      
      it "upgrades cores" do
        fake_virtual_server = SoftLayer::VirtualServer.new(mock_client, {"id" => 12345})
        fake_virtual_server.upgrade_cores!(8)
      end
      
      it "upgrades ram" do
        fake_virtual_server = SoftLayer::VirtualServer.new(mock_client, {"id" => 12345})
        fake_virtual_server.upgrade_RAM!(4)
      end
      
      it "upgrades max port speed" do
        fake_virtual_server = SoftLayer::VirtualServer.new(mock_client, {"id" => 12345})
        fake_virtual_server.upgrade_max_port_speed!(100)
      end
    end # individual component upgrades
  end  
end