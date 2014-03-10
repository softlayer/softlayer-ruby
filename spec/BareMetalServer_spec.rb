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

require 'shared_server'

describe SoftLayer::BareMetalServer do
	let (:sample_server) do
		mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "DEADBEEFBADF00D")
		allow(mock_client).to receive(:[]) do |service_name|
			service = mock_client.service_named(service_name)
			allow(service).to receive(:object_with_id).and_return(service)
			service.stub(:call_softlayer_api_with_params)
			service
		end

		SoftLayer::BareMetalServer.new(mock_client, { "id" => 12345 })
	end

	it "identifies with the SoftLayer_Virtual_Guest service" do
		sample_server.service.service_name.should == "SoftLayer_Hardware"
	end

	it_behaves_like "server with port speed" do
		let (:server) { sample_server }
	end
end