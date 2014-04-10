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

describe SoftLayer::APIParameterFilter, "#object_with_id" do
  it "should intitialize with empty parameter values" do
    filter = SoftLayer::APIParameterFilter.new
    filter.server_object_id.should be_nil
    filter.server_object_mask.should be_nil
  end

  it "should store its value in server_object_id when called " do
    filter = SoftLayer::APIParameterFilter.new
    result = filter.object_with_id(12345)
    result.server_object_id.should eql(12345)
    result.parameters.should eql({:server_object_id => 12345})
  end

  it "should allow call chaining with object_mask " do
    filter = SoftLayer::APIParameterFilter.new
    result = filter.object_with_id(12345).object_mask("fish", "cow", "duck")
    result.server_object_id.should == 12345
    result.server_object_mask.should == ["fish", "cow", "duck"]
  end
end

describe SoftLayer::APIParameterFilter, "#object_mask" do
  it "should store its value in server_object_mask when called" do
    filter = SoftLayer::APIParameterFilter.new
    result = filter.object_mask("fish", "cow", "duck")
    result.server_object_mask.should == ["fish", "cow", "duck"]
  end

  it "should allow call chaining with object_with_id" do
    filter = SoftLayer::APIParameterFilter.new
    result = filter.object_mask("fish", "cow", "duck").object_with_id(12345)
    result.server_object_id.should == 12345
    result.server_object_mask.should == ["fish", "cow", "duck"]
  end
end

describe SoftLayer::APIParameterFilter, "#method_missing" do
  it "should invoke call_softlayer_api_with_params(method_name, self, args, &block) on it's target with itself and the method_missing parameters" do
    filter = SoftLayer::APIParameterFilter.new.object_mask("fish", "cow", "duck").object_with_id(12345)

    target = mock("method_missing_target")
    target.should_receive(:call_softlayer_api_with_params).with(:getObject, filter, ["marshmallow"])

    filter.target = target

    filter.getObject("marshmallow")
  end
end
