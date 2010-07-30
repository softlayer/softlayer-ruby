# Copyright (c) 2010, SoftLayer Technologies, Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#  * Neither SoftLayer Technologies, Inc. nor the names of its contributors may
#    be used to endorse or promote products derived from this software without
#    specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

$: << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'softlayer_api'
require 'spec'

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
