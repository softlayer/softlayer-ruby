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

describe String, "#to_sl_object_mask" do
  it "converts to the string itself" do
    "blah".to_sl_object_mask.should eql("blah")
  end

  it "echos the empty string" do
    "".to_sl_object_mask.should eql("")
  end
end

describe Array,"#to_sl_object_mask" do
  it "converts an empty array to the empty string" do
    [].to_sl_object_mask.should eql("")
  end

  it "handles simple arrays" do
    ["foo", "bar", "baz"].to_sl_object_mask().should eql("foo,bar,baz")
  end

  it "flattens inner arrays to simple lists" do
    ["foo", ["bar", "baz"]].to_sl_object_mask().should eql("foo,bar,baz")
  end
end

describe Hash, "#to_sl_object_mask" do
  it "returns the empty string for an empty hash" do
      {}.to_sl_object_mask.should eql("")
  end

  it "constructs a dot expression for a simple string value" do
    {"foo" => "foobar"}.to_sl_object_mask.should eql("foo.foobar")
  end

  it "builds a bracket expression with array values" do
    {"foo" => ["one", "two", "three"]}.to_sl_object_mask.should eql("foo[one,two,three]")
  end

  it "builds bracket expressions for nested hashes" do
    {"foo" => {"sub" => "resub"}}.to_sl_object_mask.should eql("foo[sub.resub]")
  end

  it "resolves simple inner values to simple dot expressions" do
    {"top" => [ "middle1", {"middle2" => "end"}]}.to_sl_object_mask.should eql("top[middle1,middle2.end]")
  end

  it "accepts an inner empty hash and returns a mask" do
    { "ipAddress" => { "ipAddress" => {}}}.to_sl_object_mask.should eql("ipAddress[ipAddress]")
  end
end

describe SoftLayer::ObjectMaskProperty, "#initialize" do
  it "sets the name of the property if given" do
    mask_property = SoftLayer::ObjectMaskProperty.new("simple_name")
    mask_property.name.should eql("simple_name")
  end

  it "rejects nil as a property name" do
    expect { SoftLayer::ObjectMaskProperty.new(nil) }.to raise_error(ArgumentError)
  end

  it "rejects empty strings for property names" do
    expect { SoftLayer::ObjectMaskProperty.new("") }.to raise_error(ArgumentError)
  end
end

describe SoftLayer::ObjectMaskProperty, "#to_sl_object_mask" do
  it "converts a simple property to a string" do
    mask_property = SoftLayer::ObjectMaskProperty.new("simple_name")
    mask_property.to_sl_object_mask.should eql("simple_name")
  end

  it "puts parenthesis expressions in for property types" do
    mask_property = SoftLayer::ObjectMaskProperty.new("simple_name")
    mask_property.type = "property_type"
    mask_property.to_sl_object_mask.should eql("simple_name(property_type)")
  end

  it "converts simple sub-properties into a dot expression" do
    mask_property = SoftLayer::ObjectMaskProperty.new("simple_name")
    mask_property.type = "property_type"
    mask_property.subproperties = "subproperty"
    mask_property.to_sl_object_mask.should eql("simple_name(property_type).subproperty")
  end

  it "returns bracket expressions for array subproperties" do
    mask_property = SoftLayer::ObjectMaskProperty.new("simple_name")
    mask_property.subproperties = ["one", "two", "three"]
    mask_property.to_sl_object_mask.should eql("simple_name[one,two,three]")
  end

  it "accepts subproperties using a hash" do
    mask_property = SoftLayer::ObjectMaskProperty.new("simple_name")
    mask_property.subproperties = { "foo" => "subfoo" }
    mask_property.to_sl_object_mask.should eql("simple_name[foo.subfoo]")
  end
end
