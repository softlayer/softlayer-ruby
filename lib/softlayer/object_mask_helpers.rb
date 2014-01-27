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

class Hash
  def to_sl_object_mask()
    key_strings = [];

    each do |key, value|
      string_for_key = key.to_sl_object_mask
      
      if(nil == value)
        return ""
      end
      
      if value.kind_of? String then
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

class Array
  def to_sl_object_mask()
    return "" if self.empty?
    map { |item| item.to_sl_object_mask() }.flatten.join(",")
  end
end

class String
  def to_sl_object_mask()
    return clone()
  end
end

module SoftLayer
  class ObjectMaskProperty
    attr_reader :name
    attr_accessor :type
    attr_accessor :subproperties

    def initialize(property_name)
      raise(ArgumentError, "property name cannot be empty or nil") if property_name.nil? || property_name.empty?
      @name = property_name.clone
    end
    
    def to_sl_object_mask()
      object_mask_string = self.name.clone
      
      if self.type then
        object_mask_string = object_mask_string + "(#{self.type})"
      end
      
      if self.subproperties then
        subproperty_string = "";

        if self.subproperties.kind_of?(String) then
          subproperty_string = ".#{subproperties}"
        end
        
        if self.subproperties.kind_of?(Array) || self.subproperties.kind_of?(Hash) then
          subproperty_string = "[#{self.subproperties.to_sl_object_mask}]"
        end
        
        object_mask_string = object_mask_string + subproperty_string
      end
      
      object_mask_string
    end
  end
  
  class ObjectMask < ObjectMaskProperty
    def initialize()
      self.name = "mask"
    end
  end
end