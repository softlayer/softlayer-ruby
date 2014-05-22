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
  # A class representing a SoftLayer Object's property as represented
  # in an Object Mask.
  #
  # The Object Mask Parser parses Object Mask Strings into ObjectMaskProperty
  # structures.
  #
  # Another useful property ObjectMaskProperty structures is that they can
  # can merge with compatible structures to create a new structure which
  # incorporates the properties of both, but in a streamlined construct
  #
  class ObjectMaskProperty
    attr_reader :name, :type
    attr_reader :children

    def initialize(name, type = nil)
      @name = name
      @type = type
      @children = []
    end

    def to_s
      full_name = @name

      if @type && !@type.empty?
        full_name += "(#{@type})"
      end

      if @children.count == 1
        full_name + ".#{@children[0].to_s}"
      elsif @children.count > 1
        full_name + "[#{@children.collect { |child| child.to_s }.join(',')}]"
      else
        full_name
      end
    end

    def can_merge_with? (other_property)
      (self.name == other_property.name) && (self.type == other_property.type)
    end

    def add_child(new_child)
      mergeable_child = @children.find { |existing_child| existing_child.can_merge_with? new_child }
      if mergeable_child
        mergeable_child.merge new_child
      else
        @children.push new_child
      end
    end

    def add_children(new_children)
      new_children.each { |new_child| add_child(new_child) }
    end

    def merge(other_property)
      add_children other_property.children
    end
  end
end # module softlayer