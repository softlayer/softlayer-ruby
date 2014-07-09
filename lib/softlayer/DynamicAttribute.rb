#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer

  ##
  # This module is inteneded to be used by classes in the SoftLayer
  # object model. It creates a small DSL for creating attributes
  # that update themselves dynamically (usually by making requests
  # to the SoftLayer API)
  #
  # +sl_dynamic_attr+ is an implementation of a memoization scheme
  # The module creates a getter which is implemented in terms of a
  # predicate (identifying whether or not the attribute needs to be updated) and
  # an update routine
  #
  # When the getter is called, it checks the predicate routine to see if
  # the attribute needs to be updated. If it doesn't, then the getter simply
  # returns the cached value for the attribute. If the attribute does need
  # to be updated, the getter calls the update routine to get a new value
  # and caches that value off before returning it to the caller.
  #
  # Declaring a attribute adds three methods to a class and
  # a corresponding instance variable in instances of the class
  # All three are based on the name of the attribute:
  #
  # * The getter simply has the same name as the attribute
  # * The predicate routine is called +should_update_<attribute name>?+
  # * The updating routine is called +update_<attribute name>!+
  #
  # The getter can also be called with a boolean argument. If that
  # argument is true, the getter will force the attribute to be updated
  # without consulting the +should_update?+ predicate
  #
  # When a attribute is defined, the definition takes a block.
  # Inside the block there is a small DSL that allows you to
  # set the behavior of the +should_update?+ predicate and the +update_!+
  # routine.
  #
  # A attribute definition might look something like this:
  #
  #    sl_dynamic_attr :lollipop do |lollipop|
  #      lollipop.should_update? do
  #        self.lollipop_supply_is_low?
  #      end
  #
  #      lollipop.to_update do
  #        candy_store.buy_lollipops(bakers_dozen)
  #      end
  #    end
  #
  module DynamicAttribute

    # The DynamicAttributeDefinition inner class is to collect and
    # store information about how and when a sl_dynamic_attr
    # should be updated. This class is an implementation detail
    # of dynamic attributes and is not intended to be useful
    # outside of that context.
    class DynamicAttributeDefinition
      # the name of the attribute this definition is for
      attr_reader :attribute_name

      # The block to call in order to update the attribute. The
      # return value of this block should be the new value of the
      # attribute.
      attr_reader :update_block

      # The block to call to see if the attribute needs to be updated.
      attr_reader :should_update_block

      def initialize(attribute_name)
        raise ArgumentError if attribute_name.nil?
        raise ArgumentError if attribute_name.to_s.empty?

        @attribute_name = attribute_name;
        @update_block = Proc.new { nil; };
        @should_update_block = Proc.new { true; }
      end

      # This method is used to provide behavior for the
      # should_update_ predicate for the attribute
      def should_update? (&block)
        @should_update_block = block
      end

      # This method is used to provide the behavior for
      # the update_! method for the attribute.
      def to_update (&block)
        @update_block = block
      end
    end

    module ClassMethods
      # sl_dynamic_attr declares a new dynamic softlayer attribute and accepts
      # a block in which the should_update? and to_update methods for the
      # attribute are established.
      def sl_dynamic_attr (attribute_name, &block)
        attribute_definition = DynamicAttributeDefinition.new(attribute_name)

        # allow the block to update the attribute definition
        yield attribute_definition if block_given?

        # store off the attribute definition where we can find it later
        @attribute_definitions ||= {};
        @attribute_definitions[attribute_name] = attribute_definition;

        # define a method called "update_<attribute_name>!" which calls the update block
        # stored in the attribute definition
        update_symbol = "update_#{attribute_name}!".to_sym
        define_method(update_symbol, &attribute_definition.update_block)

        # define a method called "should_update_<attribute_name>?" which calls the
        # should update block stored in the attribute definition
        should_update_symbol = "should_update_#{attribute_name}?".to_sym
        define_method(should_update_symbol, &attribute_definition.should_update_block)

        # define an instance method of the class this is being
        # called on which will get the value of the attribute.
        #
        # The getter will take one argument "force_update" which
        # is treated as boolean value. If true, then the getter will
        # force the attribute to update (by using its "to_update") block.
        #
        # If the force variable is false, or not given, then the
        # getter will call the "should update" block to find out if the
        # attribute needs to be updated.
        #
        getter_name = attribute_name.to_sym
        value_instance_variable = "@#{attribute_name}".to_sym

        define_method(getter_name) do |*args|
          force_update = args[0] || false

          if force_update || __send__(should_update_symbol)
            instance_variable_set(value_instance_variable, __send__(update_symbol))
          end

          instance_variable_get(value_instance_variable)
        end
      end

      def sl_dynamic_attr_definition(attribute_name)
        @attribute_definitions[attribute_name]
      end
    end

    def self.included(included_in)
      included_in.extend(ClassMethods)
    end
  end
end
