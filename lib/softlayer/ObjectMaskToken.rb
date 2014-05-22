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
      return @type == :identifier && @value == "mask"
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