#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++



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

    # DANGER: assumes you've already checked can_merge_with? before calling this routine!
    def merge(other_property)
      add_children other_property.children
    end
  end
end # module softlayer