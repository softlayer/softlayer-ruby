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

describe SoftLayer::ObjectMaskParser, "#parse_property_set" do
  it "should parse a simple mask" do
    result = nil
    expect { result = subject.parse("mask.simple") }.to_not raise_error

    result.name.should == 'mask'
    result.children[0].name.should == 'simple'
  end

  it "should parse a simple mask set" do
    result = nil
    expect { result = subject.parse("[mask.simple1, mask.simple2]") }.to_not raise_error

    result.count.should == 2
    result[0].name.should == 'mask'
    result[0].children.count.should == 1
    result[0].children[0].name.should == "simple1"

    result[1].name.should == 'mask'
    result[1].children.count.should == 1
    result[1].children[0].name.should == "simple2"
  end

  it "should reject extraeous text" do
    expect { result = subject.parse("mask.simple, bob") }.to raise_error
    expect { result = subject.parse("mask[two,children], bob") }.to raise_error
  end

end

describe SoftLayer::ObjectMaskParser, "#parse_property_set" do
  it "should parse a simple set" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("[propertyName]")
    sequence = subject.parse_property_set(tokenizer)

    sequence.should be_kind_of(Array)
    sequence.count.should == 1

    property = sequence[0]
    property.should be_kind_of(SoftLayer::ObjectMaskProperty)
    property.name.should == "propertyName"
  end

  it "should fail if missing the starting bracket" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("propertyName]")
    expect { sequence = subject.parse_property_set(tokenizer) }.to raise_error
  end

  it "should fail if missing the ending bracket" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("[propertyName")
    expect { sequence = subject.parse_property_set(tokenizer) }.to raise_error
  end
end

describe SoftLayer::ObjectMaskParser, "#parse_property_sequence" do
  it "should parse a simple sequence" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("propertyName")
    sequence = subject.parse_property_sequence(tokenizer)

    sequence.should be_kind_of(Array)
    sequence.count.should == 1

    property = sequence[0]
    property.should be_kind_of(SoftLayer::ObjectMaskProperty)
    property.name.should == "propertyName"
  end

  it "should parse a two property sequence" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("propertyName,secondProperty")
    sequence = subject.parse_property_sequence(tokenizer)

    sequence.should be_kind_of(Array)
    sequence.count.should == 2

    property = sequence[0]
    property.should be_kind_of(SoftLayer::ObjectMaskProperty)
    property.name.should == "propertyName"

    property = sequence[1]
    property.should be_kind_of(SoftLayer::ObjectMaskProperty)
    property.name.should == "secondProperty"
  end

  it "should reject an incomplete sequence" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("propertyName,")
    expect { sequence = subject.parse_property_sequence(tokenizer) }.to raise_error
  end

  it "should reject an invalid property" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("propertyName,bad_property")
    expect { sequence = subject.parse_property_sequence(tokenizer) }.to raise_error
  end
end

describe SoftLayer::ObjectMaskParser, "#parse_property" do
  it "should parse a simple property" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("propertyName")
    property = subject.parse_property(tokenizer)

    property.should be_kind_of(SoftLayer::ObjectMaskProperty)
    property.name.should == "propertyName"
  end

  it "should parse property with a type" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("propertyName(Property_Type)")
    property = subject.parse_property(tokenizer)

    property.name.should == "propertyName"
    property.type.should == "Property_Type"
  end

  it "should parse property with a child" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("propertyName.childProperty")
    property = subject.parse_property(tokenizer)

    property.name.should == "propertyName"
    property.type.should be_nil

    property.children.count.should == 1
    property.children[0].name.should == "childProperty"
    property.children[0].type.should be_nil
    property.children[0].children.should be_empty
  end

  it "should parse property with property set" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("propertyName[firstChild,secondChild]")
    property = subject.parse_property(tokenizer)

    property.name.should == "propertyName"
    property.type.should be_nil

    property.children.count.should == 2
    property.children[0].name.should == "firstChild"
    property.children[0].type.should be_nil
    property.children[0].children.should be_empty

    property.children[1].name.should == "secondChild"
    property.children[1].type.should be_nil
    property.children[1].children.should be_empty
  end

  it "should parse property with type and dot-child" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("propertyName(Property_Type).firstChild")
    property = subject.parse_property(tokenizer)

    property.name.should == "propertyName"
    property.type.should == "Property_Type"

    property.children.count.should == 1
    property.children[0].name.should == "firstChild"
    property.children[0].type.should be_nil
    property.children[0].children.should be_empty
  end

end

describe SoftLayer::ObjectMaskParser, "#parse_property_name" do
  it "should parse a valid property name" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("propertyName")
    property_name = subject.parse_property_name(tokenizer)
    property_name.should == "propertyName"
  end

  it "should reject the empty string when looking for a property type name" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("")
    expect { subject.parse_property_name(tokenizer) }.to raise_error(SoftLayer::ObjectMaskParserError)
  end

  it "should reject invalid property names" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("Invalid_Name")
    expect { subject.parse_property_name(tokenizer) }.to raise_error(SoftLayer::ObjectMaskParserError)
  end

  it "should reject outright invalid strings" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("*!snork")
    expect { subject.parse_property_name(tokenizer) }.to raise_error(SoftLayer::ObjectMaskParserError)
  end
end

describe SoftLayer::ObjectMaskParser, "#parse_property_type" do
  it "should parse a valid property type" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("(Valid_Property_Type)")

    property_type = nil
    expect { property_type = subject.parse_property_type(tokenizer) }.to_not raise_error

    property_type.should == "Valid_Property_Type"
  end

  it "should fail if you try to provide a type list" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("(Valid_Property_Type,Some_Other_Type)")
    expect { subject.parse_property_type(tokenizer) }.to raise_error
  end

  it "should fail if you leave off the first paren" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("Valid_Property_Type)")
    expect { subject.parse_property_type(tokenizer) }.to raise_error
  end

  it "should fail if you leave off the last paren" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("Valid_Property_Type[foo,bar]")
    expect { subject.parse_property_type(tokenizer) }.to raise_error
  end
end

describe SoftLayer::ObjectMaskParser, "#parse_property_type_name" do
  it "should parse a valid property type name" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("Valid_Property_Type")
    property_type = subject.parse_property_type_name(tokenizer)
    property_type.should == "Valid_Property_Type"
  end

  it "should reject the empty string when looking for a property type name" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("")
    expect { subject.parse_property_type_name(tokenizer) }.to raise_error(SoftLayer::ObjectMaskParserError)
  end

  it "should reject invalid property type names" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("Invalid_3Property_Type")
    expect { subject.parse_property_type_name(tokenizer) }.to raise_error(SoftLayer::ObjectMaskParserError)
  end

  it "should reject outright invalid strings" do
    tokenizer = SoftLayer::ObjectMaskTokenizer.new("*!snork")
    expect { subject.parse_property_type_name(tokenizer) }.to raise_error(SoftLayer::ObjectMaskParserError)
  end
end