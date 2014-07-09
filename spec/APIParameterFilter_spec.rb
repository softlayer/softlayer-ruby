#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

describe SoftLayer::APIParameterFilter do
  let(:filter) {filter = SoftLayer::APIParameterFilter.new(nil)}

  describe "#object_with_id" do
    it "initializes with empty properties" do
      expect(filter.server_object_id).to be_nil
      expect(filter.server_object_mask).to be_nil
    end

    it "rejects nil object masks" do
      expect { filter.object_mask(nil) }.to raise_error
    end

    it "stores its value in server_object_id when called " do
      result = filter.object_with_id(12345)
      expect(result.server_object_id).to eq 12345
      expect(result.parameters).to eq({:server_object_id => 12345})
    end

    it "allows call chaining with object_mask " do
      result = filter.object_with_id(12345).object_mask("mask.fish", "mask.cow", "mask.duck")
      expect(result.server_object_id).to eq 12345
      expect(result.server_object_mask.to_s).to eq "mask[fish,cow,duck]"
    end
  end

  describe "#object_mask" do
    it "rejects nil object masks" do
      expect { filter.object_mask(nil) }.to raise_error
    end

    it "rejects calls that pass things other than strings" do
      expect { filter.object_mask(["anArray"]) }.to raise_error
      expect { filter.object_mask({"a" => "hash"}) }.to raise_error
      expect { filter.object_mask(Object.new) }.to raise_error
    end

    it "accepts strings representing a property set" do
      masked_filter = nil

      expect { masked_filter = filter.object_mask("[mask.firstProperty, mask.secondProperty]") }.to_not raise_error
      expect(masked_filter.server_object_mask).to eq "mask[firstProperty,secondProperty]"
    end

    it "stores its value in server_object_mask when called" do
      result = filter.object_mask("mask.fish", "mask[cow]", "mask(typed).duck", "mask(typed)[chicken]")
      expect(result.server_object_mask).to eq '[mask[fish,cow],mask(typed)[duck,chicken]]'
    end

    it "allows call chaining with object_with_id" do
      result = filter.object_mask("mask.fish", "mask[cow]", "mask(typed).duck", "mask(typed)[chicken]").object_with_id(12345)
      expect(result.server_object_id).to eq 12345
      expect(result.server_object_mask).to eq "[mask[fish,cow],mask(typed)[duck,chicken]]"
    end

    it "allows call chaining with other object masks" do
      result = filter.object_mask("mask.fish").object_mask("mask[cow]").object_mask("mask(typed).duck").object_mask("mask(typed)[chicken]")
      expect(result.server_object_mask).to eq "[mask[fish,cow],mask(typed)[duck,chicken]]"
    end
  end

  describe "#object_filter" do
    it "rejects nil filters" do
      expect { filter.object_filter(nil) }.to raise_error
    end

    it "stores its value in server_object_filter when called" do
      test_filter = SoftLayer::ObjectFilter.new()
      test_filter.set_criteria_for_key_path("fish", "cow")

      result = filter.object_filter(test_filter)
      expect(result.server_object_filter).to eq({"fish" => "cow"})
    end
  end

  describe "#method_missing" do
    it "invokes call_softlayer_api_with_params(method_name, self, args, &block) on its target with itself and the method_missing parameters" do
      target = double("method_missing_target")

      filter = SoftLayer::APIParameterFilter.new(target).object_mask("mask.fish", "mask[cow]", "mask(typed).duck", "mask(typed)[chicken]").object_with_id(12345)
      expect(target).to receive(:call_softlayer_api_with_params).with(:getObject, filter, ["marshmallow"])

      filter.getObject("marshmallow")
    end
  end
end
