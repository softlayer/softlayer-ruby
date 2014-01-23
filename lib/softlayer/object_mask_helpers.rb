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
  def to_sl_object_mask(base = "")
    return base if(self.empty?)

    # ask the children to convert themselves with the key as the base
    masked_children = self.map { |key, value| result = value.to_sl_object_mask(key); }.flatten

    # now resolve the children with respect to the base passed in.
    masked_children.map { |mask_item| mask_item.to_sl_object_mask(base) }
  end
end

class Array
  def to_sl_object_mask(base = "")
    return base if self.empty?
    self.map { |item| item.to_sl_object_mask(base) }.flatten
  end
end

class String
  def to_sl_object_mask(base = "")
    return base if self.empty?
    base.empty? ? self : "#{base}.#{self}"
  end
end