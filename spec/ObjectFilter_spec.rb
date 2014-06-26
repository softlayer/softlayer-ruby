#
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), '../lib'))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

describe SoftLayer::ObjectFilter do
  it "calls its construction block" do
    block_called = false;
    filter = SoftLayer::ObjectFilter.new() { 
      block_called = true;
          }

    expect(block_called).to be(true)
  end
  
  it "expects the methods in the ObjectFilterDefinitionContext to be available in its block" do
    stuff_defined = false;
    filter = SoftLayer::ObjectFilter.new() { 
      stuff_defined = !!defined?(satisfies_the_raw_condition);
        }

    expect(stuff_defined).to be(true)
  end
  
  it "is empty when no criteria have been added" do
    filter = SoftLayer::ObjectFilter.new()
    expect(filter.empty?).to be(true)
  end
  
  it "is not empty criteria have been added" do
    filter = SoftLayer::ObjectFilter.new do |filter|
      filter.accept("foobar").when_it is("baz")
    end
    
    expect(filter.empty?).to be(false)
  end
  
  it "returns criteria for a given key path" do
    test_hash = { 'one' => { 'two' => {'three' => 3}}}

    filter = SoftLayer::ObjectFilter.new()
    filter.instance_eval do 
      @filter_hash = test_hash
    end
    
    expect(filter.criteria_for_key_path("one")).to eq({'two' => {'three' => 3}})
    expect(filter.criteria_for_key_path("one.two")).to eq({'three' => 3})
    expect(filter.criteria_for_key_path("one.two.three")).to eq(3)
  end
  
  it "returns nil when asked for criteria that don't exist" do
    filter = SoftLayer::ObjectFilter.new()
    filter.set_criteria_for_key_path("some.key.path", 3)

    expect(filter.criteria_for_key_path("some.key.path")).to eq(3)
    expect(filter.criteria_for_key_path("does.not.exist")).to be_nil
    
    expect(filter.to_h).to eq({ 'some' => { 'key' => {'path' => 3}}})
  end

  it "changes criteria for a given key path" do
    filter = SoftLayer::ObjectFilter.new()
    filter.set_criteria_for_key_path("one.two.three", 3)

    expect(filter.criteria_for_key_path("one")).to eq({'two' => {'three' => 3}})
    expect(filter.criteria_for_key_path("one.two")).to eq({'three' => 3})
    expect(filter.criteria_for_key_path("one.two.three")).to eq(3)

    filter.set_criteria_for_key_path("one.two.also_two", 2)
    expect(filter.criteria_for_key_path("one.two")).to eq({'also_two' => 2, 'three' => 3})
    expect(filter.criteria_for_key_path("one.two.also_two")).to eq(2)
    
    expect(filter.to_h).to eq({"one"=>{"two"=>{"three"=>3, "also_two"=>2}}})
  end
  
  it "sets criteria in the initializer with the fancy syntax" do
    filter = SoftLayer::ObjectFilter.new do |filter|
      filter.accept("some.key.path").when_it is(3)
    end
    
    expect(filter.criteria_for_key_path("some.key.path")).to eq({'operation' => 3})
    expect(filter.to_h).to eq({"some"=>{"key"=>{"path"=>{"operation"=>3}}}})
  end
  
  it "allows the fancy syntax in a modify block" do
    filter = SoftLayer::ObjectFilter.new()

    expect(filter.criteria_for_key_path("some.key.path")).to be_nil

    filter.modify do |filter|
      filter.accept("some.key.path").when_it is(3)
    end
    
    expect(filter.criteria_for_key_path("some.key.path")).to eq({'operation' => 3})

    # can replace a criterion
    filter.modify do |filter|
      filter.accept("some.key.path").when_it is(4)
  end

    expect(filter.criteria_for_key_path("some.key.path")).to eq({'operation' => 4})
  end
    end

describe SoftLayer::ObjectFilterDefinitionContext do
  it "defines the is matcher" do
    expect(SoftLayer::ObjectFilterDefinitionContext.is(" fred")).to eq({ 'operation' => ' fred' })
    expect(SoftLayer::ObjectFilterDefinitionContext.is(42)).to eq({ 'operation' => 42 })
  end

  it "defines the is_not matcher" do
    expect(SoftLayer::ObjectFilterDefinitionContext.is_not(" fred  ")).to eq({ 'operation' => '!= fred' })
  end

  it "defines the contains matcher" do
    expect(SoftLayer::ObjectFilterDefinitionContext.contains(" fred  ")).to eq({ 'operation' => '*= fred' })
  end

  it "defines the begins_with matcher" do
    expect(SoftLayer::ObjectFilterDefinitionContext.begins_with(" fred  ")).to eq({ 'operation' => '^= fred' })
  end

  it "defines the ends_with matcher" do
    expect(SoftLayer::ObjectFilterDefinitionContext.ends_with(" fred  ")).to eq({ 'operation' => '$= fred' })
  end

  it "defines the matches_ignoring_case matcher" do
    expect(SoftLayer::ObjectFilterDefinitionContext.matches_ignoring_case(" fred  ")).to eq({ 'operation' => '_= fred' })
  end

  it "defines the is_greater_than matcher" do
    expect(SoftLayer::ObjectFilterDefinitionContext.is_greater_than(" fred  ")).to eq({ 'operation' => '> fred' })
    expect(SoftLayer::ObjectFilterDefinitionContext.is_greater_than(100)).to eq({ 'operation' => '> 100' })
  end

  it "defines the is_less_than matcher" do
    expect(SoftLayer::ObjectFilterDefinitionContext.is_less_than(" fred  ")).to eq({ 'operation' => '< fred' })
    expect(SoftLayer::ObjectFilterDefinitionContext.is_less_than(100)).to eq({ 'operation' => '< 100' })
  end

  it "defines the is_greater_or_equal_to matcher" do
    expect(SoftLayer::ObjectFilterDefinitionContext.is_greater_or_equal_to(" fred  ")).to eq({ 'operation' => '>= fred' })
    expect(SoftLayer::ObjectFilterDefinitionContext.is_greater_or_equal_to(100)).to eq({ 'operation' => '>= 100' })
  end

  it "defines the is_less_or_equal_to matcher" do
    expect(SoftLayer::ObjectFilterDefinitionContext.is_less_or_equal_to(" fred  ")).to eq({ 'operation' => '<= fred' })
    expect(SoftLayer::ObjectFilterDefinitionContext.is_less_or_equal_to(100)).to eq({ 'operation' => '<= 100' })
  end

  it "defines the contains_exactly matcher" do
    expect(SoftLayer::ObjectFilterDefinitionContext.contains_exactly(" fred  ")).to eq({ 'operation' => '~ fred' })
  end

  it "defines the does_not_contain matcher" do
    expect(SoftLayer::ObjectFilterDefinitionContext.does_not_contain(" fred  ")).to eq({ 'operation' => '!~ fred' })
    end

  it "defines the is_null matcher" do
    expect(SoftLayer::ObjectFilterDefinitionContext.is_null()).to eq({ 'operation' => 'is null' })
  end

  it "defines the is_not_null matcher" do
    expect(SoftLayer::ObjectFilterDefinitionContext.is_not_null()).to eq({ 'operation' => 'not null' })
  end

  it "defines the satisfies_the_raw_condition matcher" do
    expect(SoftLayer::ObjectFilterDefinitionContext.satisfies_the_raw_condition(
      { 'operation' => 'some_complex_operation_goes_here'})).to  eq({ 'operation' => 'some_complex_operation_goes_here'})
  end
  
  it "allows 'matches_query' strings with operators" do
    SoftLayer::OBJECT_FILTER_OPERATORS.each do |operator|
      fake_string = "#{operator}  fred  "
      expect(SoftLayer::ObjectFilterDefinitionContext.matches_query(fake_string)).to eq({ 'operation' => "#{operator} fred"})
    end
  end
  
  it "allows 'matches_query' strings for exact value match" do
    criteria = 
    expect(SoftLayer::ObjectFilterDefinitionContext.matches_query("  fred")).to eq({ 'operation' => "_= fred"})
  end
  
  it "allows 'matches_query' strings for begins_with" do
    expect(SoftLayer::ObjectFilterDefinitionContext.matches_query("fred*")).to eq({ 'operation' => "^= fred"})
  end
  
  it "allows 'matches_query' strings for ends_with" do
    expect(SoftLayer::ObjectFilterDefinitionContext.matches_query("*fred")).to eq({ 'operation' => "$= fred"})
  end
  
  it "allows 'matches_query' strings for contains" do
    expect(SoftLayer::ObjectFilterDefinitionContext.matches_query("*fred*")).to eq({ 'operation' => "*= fred"})
  end
end
