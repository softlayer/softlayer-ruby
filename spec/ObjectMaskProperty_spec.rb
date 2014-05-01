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
require 'rspec'
require 'softlayer/ObjectMaskProperty'

describe SoftLayer::ObjectMaskProperty do
  it "obtains a name when created" do
    property = SoftLayer::ObjectMaskProperty.new("propertyName")
    property.name.should == "propertyName"
    property.type.should be_nil
    property.children.should == []
  end

  it "may obtain a type when created" do
      property = SoftLayer::ObjectMaskProperty.new("propertyName", "SomeType")
      property.name.should == "propertyName"
      property.type.should == "SomeType"
      property.children.should == []
  end

  it "knows it can merge with properties that have the same name" do
    property1 = SoftLayer::ObjectMaskProperty.new("propertyName", nil)
    property2 = SoftLayer::ObjectMaskProperty.new("propertyName", nil)

    property1.can_merge_with?(property2).should be_true
  end

  it "knows it can merge with properties that have the same name and type" do
    property1 = SoftLayer::ObjectMaskProperty.new("propertyName", "SomeType")
    property2 = SoftLayer::ObjectMaskProperty.new("propertyName", "SomeType")

    property1.can_merge_with?(property2).should be_true
  end

  it "knows it cannot merge if the names don't match" do
    property1 = SoftLayer::ObjectMaskProperty.new("propertyName", nil)
    property2 = SoftLayer::ObjectMaskProperty.new("someOtherName", nil)

    property1.can_merge_with?(property2).should be_false
  end

  it "knows it cannot merge if the types don't match" do
    property1 = SoftLayer::ObjectMaskProperty.new("propertyName", "SomeType")
    property2 = SoftLayer::ObjectMaskProperty.new("propertyName", "AnotherType")

    property1.can_merge_with?(property2).should be_false
  end

  it "collects children" do
    property1 = SoftLayer::ObjectMaskProperty.new("propertyName", "SomeType")
    property2 = SoftLayer::ObjectMaskProperty.new("propertyName", "AnotherType")

    property1.add_children([property2])
    property1.children.count.should == 1
    property1.children[0].should == property2
  end

  it "collects children" do
    property1 = SoftLayer::ObjectMaskProperty.new("propertyName", "SomeType")
    property2 = SoftLayer::ObjectMaskProperty.new("propertyName", "AnotherType")

    property1.add_children([property2])
    property1.add_children([property2])

    property1.children.count.should == 1
    property1.children[0].should == property2
  end

  it "merges children" do
    property1 = SoftLayer::ObjectMaskProperty.new("parent")
    first_child = SoftLayer::ObjectMaskProperty.new("child")
    first_subchild = SoftLayer::ObjectMaskProperty.new("first_subchild")

    first_child.add_child(first_subchild)
    property1.add_child(first_child)

    property2 = SoftLayer::ObjectMaskProperty.new("parent")
    second_child = SoftLayer::ObjectMaskProperty.new("child")
    second_subchild = SoftLayer::ObjectMaskProperty.new("second_subchild")

    second_child.add_child(second_subchild)
    property2.add_child(second_child)

    property1.can_merge_with?(property2).should be_true
    property1.add_children(property2.children)

    property1.children.count.should == 1
    child = property1.children[0]
    child.name.should == "child"
    child.children.count.should == 2
    child.children.should include(first_subchild)
    child.children.should include(second_subchild)
  end
end
