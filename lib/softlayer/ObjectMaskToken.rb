#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  #
  # This class is an implementation detail of the Object Mask Parser
  # It represents a single semantic token as parsed out of an
  # Object Mask String
  #
  # The class also generates error messages that the parser can use
  # when it encounters an unexpected token
  #
  class ObjectMaskToken
    attr_reader :type
    attr_reader :value

    KnownTokenTypes = [
      :invalid_token,
      :eos,             # end of string
      :identifier,
      :property_set_start,
      :property_set_separator,
      :property_set_end,
      :property_type_start,
      :property_type_end,
      :property_child_separator,
    ]

    def initialize(token_type, token_value = nil)
      @type = token_type
      @value = token_value
    end

    def inspect
      "<#{@type.inspect}, #{@value.inspect}>"
    end

    def eql?(other_token)
      @type.eql?(other_token.type) && @value.eql?(other_token.value)
    end

    def invalid?
      return @type = :invalid_token
    end

    def end_of_string?
      return @type == :eos
    end

    def mask_root_marker?
      return @type == :identifier && (@value == "mask" || @value == "filterMask")
    end

    def valid_property_name?
      return @type == :identifier && @value.match(/\A[a-z][a-z0-9]*\z/i)
    end

    def valid_property_type?
      return @type == :identifier && @value.match(/\A[a-z][a-z0-9]*(_[a-z][a-z0-9]*)*\z/i)
    end

    def self.error_for_unexpected_token(token)
      case token.type
       when :invalid_token
         "Unrecognized token '#{token.value}'"
       when :eos
         "Unexpected end of string"
       when :identifier
         "Unexpected identifier '#{token.value}'"
       when :property_set_start
         "Unexpected '['"
       when :property_set_separator
         "Unexpected ','"
       when :property_set_end
         "Unexpected ']'"
       when :property_type_start
         "Unexpected '('"
       when :property_type_end
         "Unexpected ')'"
       when :property_child_separator
         "Unexpected '.'"
       else
         "Unexpected value (invalid token type)"
     end
    end
  end

end # module SoftLayer