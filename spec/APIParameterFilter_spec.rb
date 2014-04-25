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

describe SoftLayer::APIParameterFilter do
  let(:filter) {filter = SoftLayer::APIParameterFilter.new(nil)}

  describe "#object_with_id" do
    it "initializes with empty properties" do
      filter.server_object_id.should be_nil
      filter.server_object_mask.should be_nil
    end

    it "rejects nil object masks" do
      expect { filter.object_mask(nil) }.to raise_error
    end

    it "stores its value in server_object_id when called " do
      result = filter.object_with_id(12345)
      result.server_object_id.should eql(12345)
      result.parameters.should eql({:server_object_id => 12345})
    end

    it "allows call chaining with object_mask " do
      result = filter.object_with_id(12345).object_mask("mask.fish", "mask.cow", "mask.duck")
      result.server_object_id.should == 12345
      result.server_object_mask.should == ["mask.fish", "mask.cow", "mask.duck"]
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
      masked_filter.server_object_mask.should == ["[mask.firstProperty, mask.secondProperty]"]
    end

    it "stores its value in server_object_mask when called" do
      result = filter.object_mask("mask.fish", "mask[cow]", "mask(typed).duck", "mask(typed)[chicken]")
      result.server_object_mask.should == ["mask.fish", "mask[cow]", "mask(typed).duck", "mask(typed)[chicken]"]
    end

    it "allows call chaining with object_with_id" do
      result = filter.object_mask("mask.fish", "mask[cow]", "mask(typed).duck", "mask(typed)[chicken]").object_with_id(12345)
      result.server_object_id.should == 12345
      result.server_object_mask.should == ["mask.fish", "mask[cow]", "mask(typed).duck", "mask(typed)[chicken]"]
    end

    it "allows call chaining with other object masks" do
      result = filter.object_mask("mask.fish").object_mask("mask[cow]").object_mask("mask(typed).duck").object_mask("mask(typed)[chicken]")
      result.server_object_mask.should == ["mask.fish", "mask[cow]", "mask(typed).duck", "mask(typed)[chicken]"]
    end
  end

  describe "#object_filter" do
    it "rejects nil filters" do
      expect { filter.object_filter(nil) }.to raise_error
    end

    it "stores its value in server_object_filter when called" do
      test_filter = SoftLayer::ObjectFilter.new()
      test_filter["fish"] = "cow"

      result = filter.object_filter(test_filter)
      result.server_object_filter.should == {"fish" => "cow"}
    end
  end

  describe "#method_missing" do
    it "invokes call_softlayer_api_with_params(method_name, self, args, &block) on it's target with itself and the method_missing parameters" do
      target = double("method_missing_target")

      filter = SoftLayer::APIParameterFilter.new(target).object_mask("mask.fish", "mask[cow]", "mask(typed).duck", "mask(typed)[chicken]").object_with_id(12345)
      target.should_receive(:call_softlayer_api_with_params).with(:getObject, filter, ["marshmallow"])

      filter.getObject("marshmallow")
    end
  end
end