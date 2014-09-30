#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

require "softlayer/ObjectMaskTokenizer"
require "softlayer/ObjectMaskProperty"

module SoftLayer
  class ObjectMaskParserError < RuntimeError
  end

  #
  # A parser that can examine and validate SoftLayer Object Mask strings
  #
  # The Object Mask Parser parses Object Mask Strings into ObjectMaskProperty
  # structures.
  #
  # The Object Mask parser allows the Gem to merge Object Mask Strings
  # to avoid errors from the SoftLayer API server about duplicate properties being
  # provided when the same property is provided in different Object Masks
  #
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
        raise ObjectMaskParserError, "A valid Object mask is a 'mask' or 'filterMask' root property, or a property set containing root properties" + ObjectMaskToken.error_for_unexpected_token(token)
      end

      recognize_token(@tokenizer, :eos, "Extraneous text after object mask: ")

      if property && (property.name != "mask" && property.name != "filterMask")
        raise ObjectMaskParserError, "Object Mask must begin with a 'mask' or 'filterMask' root property"
      end

      if property_set && property_set.find { |subproperty| subproperty.name != 'mask' && subproperty.name != 'filterMask' }
        raise ObjectMaskParserError, "A root property set must contain only 'mask' or 'filterMask' root properties"
      end

      property || property_set
    end

    def parse_property_set(tokenizer)
      token = recognize_token(tokenizer, :property_set_start, "Expected '[': ")
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
      new_property.add_children(property_children) if property_children

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
end # Module SoftLaye