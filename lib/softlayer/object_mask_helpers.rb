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
  # Returns a string representing the object mask content represented by the
  # Hash.  The keys are expected to be strings.  Values that are strings convert
  # into "dotted" pairs. For example, {"ticket" => "lastUpdate"} would translate
  # to "ticket.lastUpdate".  Values that are hashes or arrays become bracketed
  # expressions.  {"ticket" => ["id", "lastUpdate"] } would become "ticket[id,lastupdate]"
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
  # Returns a string representing the object mask content represented by the
  # Array. Each value in the array is converted to it's object mask eqivalent
  # and
  def to_sl_object_mask()
    return "" if self.empty?
    map { |item| item.to_sl_object_mask() }.flatten.join(",")
  end
end

class String
  # Returns a string representing the object mask content represented by the
  # String. Strings are simply represented as copies of themselves.  We make
  # a copy in case the original String is modified somewhere along the way
  def to_sl_object_mask()
    return clone()
  end
end

class Symbol
  def to_sl_object_mask()
    self.to_s.to_sl_object_mask()
  end
end

module SoftLayer
  # An ObjectMaskProperty is a class which helps to represent more complex
  # Object Mask expressions that include the type associated with the mask.
  #
  # For example, if you are working through the SoftLayer_Account and asking
  # for all the Hardware servers on the account, and if you wish to ask
  # for the metricTrackingObjectId of the servers, you might try:
  #
  # account_service = SoftLayer::Service.new("SoftLayer_Account")
  # account_service.object_mask("id", "metricTrackingObjectId").getHardware()
  #
  # However, because the result of getHardware is a list of entities in the
  # SoftLayer_Hardware service and entities in that service do not have
  # metricTrackingObjectIds, this call will fail.
  #
  # Instead, you need to add an object mask property to the mask that
  # indicates that the metricTrackingObjectId is found in the SoftLayer_Hardware_Server
  # service. Such a thing might look like:
  #
  # tracking_id_property = SoftLayer::ObjectMaskProperty.new("metricTrackingObjectId")
  # tracking_id_property.type = "SoftLayer_Hardware_Server"
  # account_service.object_mask("id", tracking_id_property).getHardware() # asssumes account_service as above
  #
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
        object_mask_string += "(#{self.type})"
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

  # This class is largely a utility and implementation detail used when forwarding
  # an object mask to the server.  It acts as an ObjectMaskProperty with the
  # name "mask".  When a string is generated from this the result will be either
  # a simple mask (like "mask.some_property") or a compound mask of the form:
  # "mask[mask_property_structure]"
  #
  # Code using the client is unlikely to have to use this class unless you
  # are relying on the softlayer_api gem object mask helpers to generate masks
  # and then sending the mask to the server yourself.
  #
  class ObjectMask < ObjectMaskProperty
    def initialize()
      @name = "mask"
    end
  end
end