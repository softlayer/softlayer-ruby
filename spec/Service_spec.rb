#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

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
      expect(service.service_name).to eq "SoftLayer_Account"
    end

    it "construct a client, if none is given, from the API globals" do
      service = SoftLayer::Service.new("SoftLayer_Account")
      expect(service.client).to_not be_nil
      expect(service.client.username).to eq("some_default_username")
      expect(service.client.api_key).to eq("some_default_api_key")
      expect(service.client.endpoint_url).to eq(SoftLayer::API_PUBLIC_ENDPOINT)
    end

    it "construct a client with init parameters if given" do
      service = SoftLayer::Service.new("SoftLayer_Account", :username => "sample_username", :api_key => "blah")
      expect(service.client).to_not be_nil
      expect(service.client.username).to eq("sample_username")
      expect(service.client.api_key).to eq("blah")
      expect(service.client.endpoint_url).to eq(SoftLayer::API_PUBLIC_ENDPOINT)
    end

    it "accepts a client as an initialization parameter" do
      client = SoftLayer::Client.new() # authentication is taken from the globals
      service = SoftLayer::Service.new("SoftLayer_Account", :client => client)
      expect(service.client).to be(client)
    end

    it "fails if both a client and client init options are provided" do
      client = SoftLayer::Client.new() # authentication is taken from the globals
      expect { SoftLayer::Service.new("SoftLayer_Account", :client => client, :username => "sample_username", :api_key => "blah") }.to raise_error(RuntimeError)
    end
  end #describe #new
end

describe SoftLayer::Service, "xmlrpc client" do
  before(:each) do
    SoftLayer::Service.send(:public, :xmlrpc_client)
  end
  
  it "Constructs an XMLRPC client with a given timeout value based on the timeout of the client" do
    client = SoftLayer::Client.new(:username => 'fake_user', :api_key => 'fake_key', :timeout => 60)
    ticket_service = client[:Ticket]
    xmlrpc = ticket_service.xmlrpc_client()
    expect(xmlrpc.timeout).to eq 60
  end
end

describe SoftLayer::Service, "parameter filters" do
  let (:service) do
    SoftLayer::Service.new("SoftLayer_Ticket", :username => "sample_username", :api_key => "blah")
  end

  describe "#missing_method" do
    it "translates unknown methods into api calls" do
      expect(service).to receive(:call_softlayer_api_with_params).with(:getOpenTickets, nil, ["marshmallow"])
      response = service.getOpenTickets("marshmallow")
    end
  end

  describe "#object_with_id" do
    it "passes object ids to call_softlayer_api_with_params" do
        expect(service).to receive(:call_softlayer_api_with_params).with(:getObject, an_instance_of(SoftLayer::APIParameterFilter),[]) do | method_symbol, parameter_filter, other_args|
          expect(parameter_filter.server_object_id).to eq 12345
        end
        service.object_with_id(12345).getObject
    end

    it "creates a proxy object with just the object_with_id option" do
      ticket_proxy = service.object_with_id(123456)

      expect(ticket_proxy.server_object_id).to eql(123456)
      expect(service).to receive(:call_softlayer_api_with_params).with(:getObject, an_instance_of(SoftLayer::APIParameterFilter), []) do |method_selector, filter, arguments|
        expect(filter).to_not be_nil
        expect(filter.target).to eq service
        expect(filter.server_object_id).to eq 123456
      end

      ticket_proxy.getObject
    end

    it "doesn't change an object_mask proxy when used in a call chain with that proxy" do
      masked_proxy = service.object_mask("mask.fish", "mask[cow]", "mask(typed).duck", "mask(typed)[chicken]")

      expect(service).to receive(:call_softlayer_api_with_params).with(:getObject, an_instance_of(SoftLayer::APIParameterFilter),[])
      masked_proxy.object_with_id(123456).getObject

      expect(masked_proxy.server_object_id).to be_nil
      expect(masked_proxy.server_object_mask).to eq "[mask[fish,cow],mask(typed)[duck,chicken]]"
    end
  end

  describe "#object_mask" do
    it "constructs a parameter filter with the correct object mask" do
      filter = service.object_mask("mask.fish", "mask[cow]", "mask(typed).duck", "mask(typed)[chicken]")

      expect(filter).to_not be_nil
      expect(filter.target).to be(service)
      expect(filter.server_object_mask).to eq "[mask[fish,cow],mask(typed)[duck,chicken]]"
    end

    it "creates a proxy object that can pass an object mask to an API call" do
      ticket_proxy = service.object_mask("mask.fish", "mask[cow]", "mask(typed).duck", "mask(typed)[chicken]")

      expect(ticket_proxy.server_object_mask).to eq "[mask[fish,cow],mask(typed)[duck,chicken]]"
      expect(service).to receive(:call_softlayer_api_with_params).with(:getObject, an_instance_of(SoftLayer::APIParameterFilter), []) do |method_selector, filter, arguments|
        expect(filter).to_not be_nil
        expect(filter.target).to eq service
        expect(filter.server_object_mask).to eq "[mask[fish,cow],mask(typed)[duck,chicken]]"
      end
      ticket_proxy.getObject
    end

    it "doesn't change an object_with_id proxy when used in a call chain with that proxy" do
      ticket_proxy = service.object_with_id(123456)

      expect(service).to receive(:call_softlayer_api_with_params).with(:getObject, an_instance_of(SoftLayer::APIParameterFilter),[])
      ticket_proxy.object_mask("mask.fish", "mask[cow]", "mask(typed).duck", "mask(typed)[chicken]").getObject

      expect(ticket_proxy.server_object_id).to eql(123456)
      expect(ticket_proxy.server_object_mask).to be_nil
    end

    it "rejects improperly formatted masks" do
      expect { ticket_proxy = service.object_mask(["fish", "cow", "duck"]) }.to raise_error(ArgumentError)
      expect { ticket_proxy = service.object_mask({"fish" => "cow"}) }.to raise_error(ArgumentError)
    end
  end

  describe "#object_filter" do
    let (:object_filter) do
      object_filter = SoftLayer::ObjectFilter.new() do |filter|
        filter.set_criteria_for_key_path("key", "value")
      end
      object_filter
    end

    it "constructs a parameter filter with the given ObjectFilter" do
      parameter_filter = service.object_filter(object_filter)
      expect(parameter_filter).to_not be_nil
      expect(parameter_filter.target).to eq service
      expect(parameter_filter.server_object_filter).to eq object_filter.to_h
    end

    it "passes an object filter through to an API call" do
      expect(service).to receive(:call_softlayer_api_with_params).with(:getObject, an_instance_of(SoftLayer::APIParameterFilter),[]) do |method_name, parameters, args|
        expect(parameters.server_object_filter).to eq object_filter.to_h
      end

      service.object_filter(object_filter).getObject
    end
  end

  describe "#result_limit" do
    it "constructs a parameter filter with the correct result limit" do
      filter = service.result_limit(10, 20)

      expect(filter).to_not be_nil
      expect(filter.target).to be(service)
      expect(filter.server_result_offset).to eq 10
      expect(filter.server_result_limit).to eq 20
    end
  end

  describe "#related_service_named" do
    it "can provide related services" do
      related_service = service.related_service_named("SoftLayer_Hardware")
      expect(related_service.service_name).to eq("SoftLayer_Hardware")
      expect(related_service.client).to be(service.client)
    end
  end
end #describe SoftLayer::Service
