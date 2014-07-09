#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

# class TestClass
#   include SoftLayer::DynamicAttribute
#
#   sl_dynamic_attr(:test_attribute) do |attribute|
#     attribute.refresh_every(5 * 60)      #refresh every 5 minutes
#     attribute.update do
#       "test_attribute value!"
#     end
#   end
# end

describe SoftLayer::DynamicAttribute do
  context "when included in a class" do
    before do
      class TestClass
        include SoftLayer::DynamicAttribute
      end
    end

    it "defines ::sl_dynamic_attr in the class" do
      expect(TestClass).to respond_to(:sl_dynamic_attr)
    end

    it "defines ::sl_dynamic_attr_definition in the class" do
      expect(TestClass).to respond_to(:sl_dynamic_attr_definition)
    end
  end

  describe "::sl_dynamic_attr" do
    before do
      class TestClass
        include SoftLayer::DynamicAttribute
        sl_dynamic_attr(:test_attribute) { |test_attribute| }
      end
    end

    it "adds a attribute definition" do
      expect(TestClass.sl_dynamic_attr_definition(:test_attribute)).to_not be_nil
    end

    it "adds a attribute getter to instances" do
      sample_instance = TestClass.new()
      expect(sample_instance).to respond_to(:test_attribute)

      expect(sample_instance.test_attribute).to be_nil
    end

    it "adds a predicate to check for updates" do
      sample_instance = TestClass.new()
      expect(sample_instance).to respond_to(:should_update_test_attribute?)
    end

    it "adds a method to perform updates" do
      sample_instance = TestClass.new()
      expect(sample_instance).to respond_to(:update_test_attribute!)
    end
  end

  describe "a simple attribute definition" do
    before do
      class TestClass
        include SoftLayer::DynamicAttribute
        sl_dynamic_attr(:test_attribute) do |rsrc|
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

      expect(sample_instance.instance_variable_defined?(:@test_attribute)).to be(false)

      expect(sample_instance).to receive(:method_in_test_class_instance_context)
      expect(sample_instance.test_attribute).to eq "Value update accomplished!"
      expect(sample_instance.instance_variable_defined?(:@test_attribute)).to be(true)
      expect(sample_instance.instance_variable_get(:@test_attribute)).to eq "Value update accomplished!"
    end
  end

  describe "a attribute with delayed update" do
    before do
      class TestClass
        include SoftLayer::DynamicAttribute
        sl_dynamic_attr(:test_attribute) do |rsrc|
          rsrc.should_update? do
            @last_test_attribute_update ||= Time.at(0)
            (Time.now - @last_test_attribute_update) > 0.5 # update once a second
          end

          rsrc.to_update do
            @last_test_attribute_update = Time.now
            Time.now
          end
        end
      end # TestClass
    end

    it "should obtain an updated value when called" do
      sample_instance = TestClass.new
      last_update = sample_instance.test_attribute
      next_update = sample_instance.test_attribute
      expect(next_update).to eq last_update
      sleep(0.75)
      final_update = sample_instance.test_attribute
      expect(final_update).to_not eq last_update
    end
  end

  describe SoftLayer::DynamicAttribute::DynamicAttributeDefinition do
    let(:test_definition) do
      SoftLayer::DynamicAttribute::DynamicAttributeDefinition.new(:test_attribute)
    end

    it "raises an exception if passed an invalid name" do
      expect { SoftLayer::DynamicAttribute::DynamicAttributeDefinition.new(nil) }.to raise_error
      expect { SoftLayer::DynamicAttribute::DynamicAttributeDefinition.new("") }.to raise_error
    end

    it "has valid initial values" do
      expect(test_definition.attribute_name).to be(:test_attribute)
      expect(test_definition.update_block).to_not be_nil
    end

    it "allows DSL syntax" do
      test_definition.should_update? { "Yea!" }
      test_definition.to_update do
        "test_attribute value!"
      end

      expect(test_definition.update_block.call).to eq "test_attribute value!"
      expect(test_definition.should_update_block.call).to eq "Yea!"
    end
  end
end
