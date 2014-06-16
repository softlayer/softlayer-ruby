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

##
# This extension to the Hash class to allows object masks to be constructed
# from built-in Ruby types and converted to object masks strings for presentation
# to the SoftLayer API
class Hash
  # Given a hash, generate an Object Mask string from the structure
  # found within the hash. This allows object masks to be constructed
  # as hashes, then converted to strings when they must be passed
  # to the API. The routine does some very rudimentary validation to
  # ensure that the hash represents a valid object mask, but care must
  # still be taken when constructing the hash.
  def to_sl_object_mask()
    raise RuntimeError, "An object mask must contain properties" if empty?
    raise RuntimeError, "An object mask must start with root properties" if keys().find { |key| !__valid_root_property_key?(key) }

    key_strings = __sl_object_mask_properties_for_keys();
    key_strings.count > 1 ? "[#{key_strings.join(',')}]" : "#{key_strings[0]}"
  end

  # Returns a string representing the hash as a property within a larger
  # object mask. This routine is an implementation detail used in the conversion
  # of hashes to object mask strings. You should not have to call this method directly.
  def _to_sl_object_mask_property()
    key_strings = __sl_object_mask_properties_for_keys();
    "#{key_strings.join(',')}"
  end

  private

  def __valid_root_property_key?(key_string)
    return key_string == "mask" || (0 == (key_string =~ /\Amask\([a-z][a-z0-9_]*\)\z/i))
  end

  def __sl_object_mask_properties_for_keys
    key_strings = [];

    each do |key, value|
      return "" if !value

      string_for_key = key._to_sl_object_mask_property

      if value.kind_of?(String) || value.kind_of?(Symbol) then
        string_for_key = "#{string_for_key}.#{value._to_sl_object_mask_property}"
      end

      if value.kind_of?(Array) || value.kind_of?(Hash) then
        value_string = value._to_sl_object_mask_property
        if value_string && !value_string.empty?
          string_for_key = "#{string_for_key}[#{value_string}]"
        end
      end

      key_strings.push(string_for_key)
    end

    key_strings
  end
end

##
# SoftLayer Extensions to the Array class to support using arrays to create
# object masks
class Array
  # Returns a string representing the object mask content represented by the
  # Array. Each value in the array is converted to its object mask eqivalent
  # This routine is an implementation detail used in the conversion of hashes
  # to object mask strings. You should not have to call this method directly.
  def _to_sl_object_mask_property()
    return "" if self.empty?
    property_content = map { |item| item ? item._to_sl_object_mask_property() : nil  }.compact.flatten.join(",")
    "#{property_content}"
  end
end

##
# SoftLayer Extensions to the String class to support using strings to create
# object masks
class String
  # Returns a string representing the object mask content represented by the
  # String. Strings are simply represented as copies of themselves. We make
  # a copy in case the original String is modified somewhere along the way
  # This routine is an implementation detail used in the conversion of hashes
  # to object mask strings. You should not have to call this method directly.
  def _to_sl_object_mask_property()
    return self.strip
  end
end

##
# SoftLayer Extensions to the Symbol class to support using symbols to create
# object masks
class Symbol
  # Converts the Symbol to a string, then converts the string to an
  # object mask property. This routine is an implementation detail used in
  # the conversion of hashes to object mask strings. You should not have to
  # call this method directly.
  def _to_sl_object_mask_property()
    self.to_s._to_sl_object_mask_property()
  end
end
