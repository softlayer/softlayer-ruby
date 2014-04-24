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
  # Returns a string representing the object mask content represented by the
  # Hash.  The keys are expected to be strings.  Values that are strings convert
  # into "dotted" pairs. For example, <tt>{"ticket" => "lastUpdate"}</tt> would translate
  # to <tt>ticket.lastUpdate</tt>.  Values that are hashes or arrays become bracketed
  # expressions.  <tt>{"ticket" => ["id", "lastUpdate"] }</tt> would become <tt>ticket[id,lastupdate]</tt>
  def to_sl_object_mask()
    key_strings = [];

    each do |key, value|
      string_for_key = key.to_sl_object_mask

      if(nil == value)
        return ""
      end

      if value.kind_of?(String) || value.kind_of?(Symbol) then
        string_for_key = "#{string_for_key}.#{value.to_sl_object_mask}"
      end

      if value.kind_of?(Array) || value.kind_of?(Hash) then
        value_string = value.to_sl_object_mask
        if value_string && !value_string.empty?
          string_for_key = "#{string_for_key}[#{value.to_sl_object_mask}]"
        end
      end

      key_strings.push(string_for_key)
    end

    return key_strings.join(",")
  end  
end

# Ruby Array Class
class Array
  # Returns a string representing the object mask content represented by the
  # Array. Each value in the array is converted to its object mask eqivalent
  def to_sl_object_mask()
    return "" if self.empty?
    map { |item| item.to_sl_object_mask() }.flatten.join(",")
  end
end

# Ruby String Class
class String
  # Returns a string representing the object mask content represented by the
  # String. Strings are simply represented as copies of themselves.  We make
  # a copy in case the original String is modified somewhere along the way
  def to_sl_object_mask()
    return clone()
  end
  
  # returns true if the string appears to represent the root property
  # of an object mask.  This doesn't parse the mask entirely, but 
  # requires that it begins with "mask" and contains only valid
  # object mask characters.
  def sl_root_property?
    (self.strip =~ /\Amask[\[\]\(\)a-z0-9_\.\s\,]+\z/i) == 0
  end
  
  # returns true if the string appears to represent a root property
  # set of an object mask.  This breaks out the individual components
  # of the "array-like" portion of the string and checks to see that
  # each represents a root property
  def sl_root_property_set?
    is_property_set = false

    match_data = self.strip.match(/\[(.*)\]/m)
    if match_data
      content = match_data[1].split(',').collect{ |part| part.strip }
      
      if content.count > 0
        is_property_set = content.inject(true) do |is_property_set, content_item|
          is_property_set && content_item.sl_root_property?
        end
      end
    end

    is_property_set
  end
  
end

# Ruby Symbol Class
class Symbol
  def to_sl_object_mask()
    self.to_s.to_sl_object_mask()
  end
end

# Checks a string to see if it is a well-formatted 
# Object Mask string.  At the moment this is a pretty 
# primitive test.
def validate_mask_string(mask_string)
  ((mask_string =~ /\Amask/) == 0) || ((mask_string =~ /\A\[/) == 0)
end