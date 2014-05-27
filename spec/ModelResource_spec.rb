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

# class TestClass
#   include SoftLayer::ModelResource
#
#   softlayer_resource(:test_resource) do |resource|
#     resource.refresh_every(5 * 60)      #refresh every 5 minutes
#     resource.update do
#       "test_resource value!"
#     end
#   end
# end

describe SoftLayer::ModelResource do
  context "when included in a class" do
    before do
      class TestClass
        include SoftLayer::ModelResource
      end
    end

    it "defines ::softlayer_resource in the class" do
      TestClass.should respond_to(:softlayer_resource)
    end

    it "defines ::softlayer_resource_definition in the class" do
      TestClass.should respond_to(:softlayer_resource_definition)
    end
  end

  describe "::softlayer_resource" do
    before do
      class TestClass
        include SoftLayer::ModelResource
        softlayer_resource(:test_resource) { |test_resource| }
      end
    end

    it "adds a resource definition" do
      TestClass.softlayer_resource_definition(:test_resource).should_not be_nil
    end

    it "adds a resource getter to instances" do
      sample_instance = TestClass.new()
      sample_instance.should respond_to(:test_resource)

      sample_instance.test_resource.should be_nil
    end

    it "adds a predicate to check for updates" do
      sample_instance = TestClass.new()
      sample_instance.should respond_to(:should_update_test_resource?)
    end

    it "adds a method to perform updates" do
      sample_instance = TestClass.new()
      sample_instance.should respond_to(:update_test_resource!)
    end
  end

  describe "a simple resource definition" do
    before do
      class TestClass
        include SoftLayer::ModelResource
        softlayer_resource(:test_resource) do |rsrc|
          rsrc.to_update do
            method_in_test_class_instance_context
            "Value update accomplished!"
          end
        end
        def method_in_test_class_instance_context
          nil
        end
      end # TestClass
    end

    it "should obtain an updated value when called" do
      sample_instance = TestClass.new

      sample_instance.instance_variable_defined?(:@test_resource).should be_false

      sample_instance.should_receive(:method_in_test_class_instance_context)
      sample_instance.test_resource.should == "Value update accomplished!"
      sample_instance.instance_variable_defined?(:@test_resource).should be_true
      sample_instance.instance_variable_get(:@test_resource).should == "Value update accomplished!"
    end
  end

  describe "a resource with delayed update" do
    before do
      class TestClass
        include SoftLayer::ModelResource
        softlayer_resource(:test_resource) do |rsrc|
          rsrc.should_update? do
            @last_test_resource_update ||= Time.at(0)
            (Time.now - @last_test_resource_update) > 0.5 # update once a second
          end

          rsrc.to_update do
            @last_test_resource_update = Time.now
            Time.now
          end
        end
      end # TestClass
    end

    it "should obtain an updated value when called" do
      sample_instance = TestClass.new
      last_update = sample_instance.test_resource
      next_update = sample_instance.test_resource
      next_update.should == last_update
      sleep(0.75)
      final_update = sample_instance.test_resource
      final_update.should_not == last_update
    end
  end

  describe SoftLayer::ModelResource::ResourceDefinition do
    let(:test_definition) do
      SoftLayer::ModelResource::ResourceDefinition.new(:test_resource)
    end

    it "raises an exception if passed an invalid name" do
      expect { SoftLayer::ModelResource::ResourceDefinition.new(nil) }.to raise_error
      expect { SoftLayer::ModelResource::ResourceDefinition.new("") }.to raise_error
    end

    it "has valid initial values" do
      test_definition.resource_name.should be(:test_resource)
      test_definition.update_block.should_not be_nil
    end

    it "allows DSL syntax" do
      test_definition.should_update? { "Yea!" }
      test_definition.to_update do
        "test_resource value!"
      end

      test_definition.update_block.call.should == "test_resource value!"
      test_definition.should_update_block.call.should == "Yea!"
    end
  end
end
