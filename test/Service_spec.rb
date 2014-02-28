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
require 'rspec/autorun'

describe SoftLayer::Service, "#new" do
  describe "#new" do
    before(:each) do
      $SL_API_USERNAME = "some_default_username"
      $SL_API_KEY = "some_default_api_key"
      $SL_API_BASE_URL = SoftLayer::API_PUBLIC_ENDPOINT
    end

    after(:each) do
      $SL_API_USERNAME = nil
      $SL_API_KEY = nil
      $SL_API_BASE_URL = SoftLayer::API_PUBLIC_ENDPOINT
    end

    it "rejects a nil or empty service name" do
      expect {service = SoftLayer::Service.new(nil)}.to raise_error
      expect {service = SoftLayer::Service.new("")}.to raise_error
      expect {service = SoftLayer::Service.new('')}.to raise_error
    end

    it "assigns the service name for the service" do
      service = SoftLayer::Service.new("SoftLayer_Account")
      service.service_name.should == "SoftLayer_Account"
    end

    it "construct a client, if none is given, from the API globals" do
      service = SoftLayer::Service.new("SoftLayer_Account")
      service.client.should_not be_nil
      service.client.username.should eq("some_default_username")
      service.client.api_key.should eq("some_default_api_key")
      service.client.endpoint_url.should eq(SoftLayer::API_PUBLIC_ENDPOINT)
    end

    it "accepts a client as an initialization parameter" do
      client = SoftLayer::Client.new() # authentication is taken from the globals
      service = SoftLayer::Service.new("SoftLayer_Account", :client => client)
      service.client.should be(client)
    end
  end #describe #new
end

describe SoftLayer::Service do
  let (:service) do
    SoftLayer::Service.new("SoftLayer_Ticket", :username => "sample_username", :api_key => "blah")
  end

  describe "#missing_method" do
    it "translates unknown methods into api calls" do
      service.should_receive(:call_softlayer_api_with_params).with(:getOpenTickets, nil, ["marshmallow"])
      response = service.getOpenTickets("marshmallow")
    end
  end

  describe "#object_with_id" do
    it "passes object ids to call_softlayer_api_with_params" do
        service.should_receive(:call_softlayer_api_with_params).with(:getObject, an_instance_of(SoftLayer::APIParameterFilter),[]) do | method_symbol, parameter_filter, other_args|
          parameter_filter.server_object_id.should == 12345
        end
        service.object_with_id(12345).getObject
    end

    it "creates a proxy object with just the object_with_id option" do
      ticket_proxy = service.object_with_id(123456)

      ticket_proxy.server_object_id.should eql(123456)
      service.should_receive(:call_softlayer_api_with_params).with(:getObject, an_instance_of(SoftLayer::APIParameterFilter), []) do |method_selector, filter, arguments|
        filter.should_not be_nil
        filter.target.should == service
        filter.server_object_id.should == 123456
      end

      ticket_proxy.getObject
    end

    it "doesn't change an object_mask proxy when used in a call chain with that proxy" do
      masked_proxy = service.object_mask("fish", "cow", "duck")

      service.should_receive(:call_softlayer_api_with_params).with(:getObject, an_instance_of(SoftLayer::APIParameterFilter),[])
      masked_proxy.object_with_id(123456).getObject

      masked_proxy.server_object_id.should be_nil
      masked_proxy.server_object_mask.should eql(["fish", "cow", "duck"])
    end
  end

  describe "#object_mask" do
    it "constructs a parameter filter with the correct object mask" do
      filter = service.object_mask("fish", "cow", "duck")

      filter.should_not be_nil
      filter.target.should === service
      filter.server_object_mask.should == ["fish", "cow", "duck"]
    end

    it "creates a proxy object that can pass an object mask to an API call" do
      ticket_proxy = service.object_mask("fish", "cow", "duck")

      ticket_proxy.server_object_mask.should eql(["fish", "cow", "duck"])
      service.should_receive(:call_softlayer_api_with_params).with(:getObject, an_instance_of(SoftLayer::APIParameterFilter), []) do |method_selector, filter, arguments|
        filter.should_not be_nil
        filter.target.should == service
        filter.server_object_mask.should == ["fish", "cow", "duck"]
      end
      ticket_proxy.getObject
    end

    it "doesn't change an object_with_id proxy when used in a call chain with that proxy" do
      ticket_proxy = service.object_with_id(123456)

      service.should_receive(:call_softlayer_api_with_params).with(:getObject, an_instance_of(SoftLayer::APIParameterFilter),[])
      ticket_proxy.object_mask("fish", "cow", "duck").getObject

      ticket_proxy.server_object_id.should eql(123456)
      ticket_proxy.server_object_mask.should be_nil
    end
  end

  describe "#object_filter" do
    let (:object_filter) do 
      object_filter = SoftLayer::ObjectFilter.new()
      object_filter["key"] = "value"
      object_filter
    end
    
    it "constructs a parameter filter with the given ObjectFilter" do
      parameter_filter = service.object_filter(object_filter)
      parameter_filter.should_not be_nil
      parameter_filter.target.should == service
      parameter_filter.server_object_filter.should == object_filter
    end
    
    it "passes an object filter through to an API call" do
      service.should_receive(:call_softlayer_api_with_params).with(:getObject, an_instance_of(SoftLayer::APIParameterFilter),[]) do |method_name, parameters, args|
        parameters.server_object_filter.should == object_filter
      end

      service.object_filter(object_filter).getObject
    end
  end

  describe "#result_limit" do
    it "constructs a parameter filter with the correct result limit" do
      filter = service.result_limit(10, 20)

      filter.should_not be_nil
      filter.target.should === service
      filter.server_result_offset.should == 10
      filter.server_result_limit.should == 20
    end
  end

  describe "#related_service_named" do
    it "can provide related services" do
      related_service = service.related_service_named("SoftLayer_Hardware")
      related_service.service_name.should eq("SoftLayer_Hardware")
      related_service.client.should be(service.client)
    end
  end
end #describe SoftLayer::Service

