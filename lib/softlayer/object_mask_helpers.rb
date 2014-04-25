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

# Ruby Hash Class
class Hash
  def __valid_root_property_key?(key_string)
    return key_string == "mask" || (0 == (key_string =~ /\Amask\([a-z][a-z0-9_]*\)\z/i))
  end
  
  def to_sl_object_mask()
    raise RuntimeError, "An object mask must contain properties" if empty?
    raise RuntimeError, "An object mask must start with root properties" if keys().find { |key| !__valid_root_property_key?(key) }

    key_strings = __sl_object_mask_properties_for_keys();
    key_strings.count > 1 ? "[#{key_strings.join(',')}]" : "#{key_strings[0]}"
  end
  
  def to_sl_object_mask_property()
    key_strings = __sl_object_mask_properties_for_keys();
    "#{key_strings.join(',')}"
  end
  
  def __sl_object_mask_properties_for_keys
    key_strings = [];

    each do |key, value|
      string_for_key = key.to_sl_object_mask_property

      if(nil == value)
        return ""
      end

      if value.kind_of?(String) || value.kind_of?(Symbol) then
        string_for_key = "#{string_for_key}.#{value.to_sl_object_mask_property}"
      end

      if value.kind_of?(Array) || value.kind_of?(Hash) then
        value_string = value.to_sl_object_mask_property
        if value_string && !value_string.empty?
          string_for_key = "#{string_for_key}[#{value_string}]"
        end
      end

      key_strings.push(string_for_key)
    end
    
    key_strings
  end
end

# Ruby Array Class
class Array
  # Returns a string representing the object mask content represented by the
  # Array. Each value in the array is converted to its object mask eqivalent
  def to_sl_object_mask_property()
    return "" if self.empty?
    property_content = map { |item| item.to_sl_object_mask_property() }.flatten.join(",")
    "#{property_content}"
  end
end

# Ruby String Class
class String
  # Returns a string representing the object mask content represented by the
  # String. Strings are simply represented as copies of themselves.  We make
  # a copy in case the original String is modified somewhere along the way
  def to_sl_object_mask_property()
    return self.strip
  end
end

# Ruby Symbol Class
class Symbol
  def to_sl_object_mask()
    self.to_s.to_sl_object_mask()
  end
end