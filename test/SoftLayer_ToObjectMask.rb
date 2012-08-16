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
require 'rspec'
require 'rspec/autorun'

describe String, "#to_sl_object_mask" do
  it "should echo back a string with no base" do
    "blah".to_sl_object_mask.should eql("blah")
  end

  it "should prepend the base with a dot if given" do
    "blah".to_sl_object_mask("foo").should eql("foo.blah")
  end

  it "should return the empty string if given the empty string with no base" do
    "".to_sl_object_mask.should eql("")
  end

  it "should return the base with no dot if applied to the empty string" do
    "".to_sl_object_mask("foo").should eql("foo")
  end
end

describe Array,"#to_sl_object_mask" do
  it "should return and empty string if run on an empty array" do
    [].to_sl_object_mask.should eql("")
  end

  it "should call to_sl_object_mask passing the base to all its elements" do
    proxy = "Hello"
    proxy.should_receive(:to_sl_object_mask).with("")
    [proxy].to_sl_object_mask

    proxy = "Hello"
    proxy.should_receive(:to_sl_object_mask).with("foo")
    [proxy].to_sl_object_mask('foo')
  end

  it "should flatten any arrays inside of itself" do
    ["foo", ["bar", "baz"]].to_sl_object_mask("buz").should eql(["buz.foo", "buz.bar", "buz.baz"])
  end
end

describe Hash, "#to_sl_object_mask" do
  it "should return an empty string if run on an empty hash" do
	  {}.to_sl_object_mask.should eql("")
  end

  it "should call to_sl_object_mask on values with the key as the base" do
    proxy = "value"
    proxy.should_receive(:to_sl_object_mask).with("key").and_return("key.value")
    mask_elements = {"key" => proxy}.to_sl_object_mask
    mask_elements.should eql(["key.value"])
  end

  it "should resolve the mapped values with the base provided" do
    {"top" => [ "middle1", {"middle2" => "end"}]}.to_sl_object_mask.should eql(["top.middle1", "top.middle2.end"])
  end
  
  it "should handle a complex hash object mask with an inner empty hash" do
    { "ipAddress" => { "ipAddress" => {}}}.to_sl_object_mask.should eql(["ipAddress.ipAddress"])
  end
  
end