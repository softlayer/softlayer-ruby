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

require "softlayer/ObjectMaskTokenizer"

class ObjectMaskParserError < RuntimeError
end

class ObjectMaskProperty
  attr_reader :name, :type
  attr_accessor :children

  def initialize(name, type = nil)
    @name = name
    @type = type
  end
end

class ObjectMaskParser
  attr_reader :stack

  def initialize()
    @stack = []
  end

  def parse(mask_string)
    @tokenizer = ObjectMaskTokenizer.new(mask_string)

    token = @tokenizer.current_token
    if token.type == :identifier
      property = parse_property(@tokenizer)
    elsif token.type == :property_set_start
      property_set = parse_property_set(@tokenizer)
    else
      raise ObjectMaskParserError, "Object Mask must begin with a 'mask' root property, or a property set" + ObjectMaskToken.error_for_unexpected_token(token)
    end

    if property && property.name != "mask"
      raise ObjectMaskParserError, "Object Mask must begin with a 'mask' root property"
    end

    if property_set && property_set.find { |subproperty| subproperty.name != 'mask'}
      raise ObjectMaskParserError, "A root property set must contain only root properties"
    end

    property || property_set
  end

  def parse_property_set(tokenizer)
    token = recognize_token(tokenizer, :property_set_start, "Expected '[]': ")
    property_sequence = parse_property_sequence(tokenizer)
    token = recognize_token(tokenizer, :property_set_end, "Expected ']': ")
    property_sequence
  end

  def parse_property_sequence(tokenizer)
    first_property = parse_property(tokenizer)

    other_children = []
    token = tokenizer.current_token
    if(token.type.equal?(:property_set_separator))
      # skip the separator
      tokenizer.next_token

      # find another property
      other_children = parse_property_sequence(tokenizer)
    end

    return other_children.unshift(first_property)
  end

  def parse_property (tokenizer)
    property_name = nil
    property_type = nil
    property_children = nil

    property_name = parse_property_name(tokenizer)

    # look for a property type
    property_type = nil
    token = tokenizer.current_token
    if(token.type.equal?(:property_type_start))
      property_type = parse_property_type(tokenizer)
    end

    token = tokenizer.current_token
    if(token.type.equal?(:property_child_separator))
      property_children = [ parse_property_child(tokenizer) ]
    elsif (token.type.equal?(:property_set_start))
      property_children = parse_property_set(tokenizer)
    end

    new_property = ObjectMaskProperty.new(property_name, property_type)
    new_property.children = property_children
    
    return new_property
  end
  
  def parse_property_child(tokenizer)
    token = recognize_token(tokenizer, :property_child_separator, "Expected a '.': ")
    parse_property(tokenizer)
  end

  def parse_property_name(tokenizer)
    token = recognize_token(tokenizer, :identifier, "Expected a valid property type: ") { |token| token.valid_property_name? }
    return token.value
  end

  def parse_property_type(tokenizer)
    token = recognize_token(tokenizer, :property_type_start, "Expected '(': ")
    property_type = parse_property_type_name(tokenizer)
    token = recognize_token(tokenizer, :property_type_end, "Expected ')': ")
    return property_type
  end

  def parse_property_type_name(tokenizer)
    token = recognize_token(tokenizer, :identifier, "Expected a valid property type: ") { |token| token.valid_property_type? }
    return token.value
  end

  def recognize_token(tokenizer, expected_type, error_string, &predicate)
    token = tokenizer.current_token
    if token.type.equal?(expected_type) && (!predicate || predicate.call(token))
      tokenizer.next_token
    else
      raise ObjectMaskParserError, error_string + ObjectMaskToken.error_for_unexpected_token(token)
      token = nil;
    end

    return token
  end

end
