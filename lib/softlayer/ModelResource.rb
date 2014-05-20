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

  ##
  # This module is inteneded to be used by classes in the SoftLayer
  # object model.  It creates a small DSL for creating SoftLayer Resources
  #
  # +softlayer_resource+ is an implementation of a memoization scheme
  # The module creates a getter which is implemented in terms of a
  # predicate (identifying whether or not the resource needs to be updated) and
  # an update routine
  #
  # When the getter is called, it checks the predicate routine to see if
  # the resource needs to be updated. If it doesn't, then the getter simply
  # returns the cached value for the resource. If the resource does need
  # to be updated, the getter calls the update routine to get a new value
  # and caches that value off before returning it to the caller.
  #
  # Declaring a resource will create three routines and an instance
  # variable based on the name of the resource
  #
  # * The getter simply has the same name as the resource
  # * The predicate routine is called +should_update_<resource name>?+
  # * The updating routine is called +update_<resource name>!+
  #
  # The getter can also be called with a boolean argument.  If that
  # argument is true, the getter will force the resource to be updated
  # without consulting the +should_update_+ predicate
  #
  # When a resource is defined, the definition takes a block
  # inside that block there is a small DSL that allows you to
  # set the behavior of the +should_update_+ predicate and the +update_+
  # routine.
  #
  # A resource definition might look something like this:
  #
  #    softlayer_resource :lollipop do |lollipop|
  #      lollipop.should_update_if do
  #        self.lollipop_supply_is_low?
  #      end
  #
  #      lollipop.to_update do
  #        candy_store.buy_lollipops(bakers_dozen)
  #      end
  #    end
  #
  module ModelResource

    # ResourceDefinition inner class used to collect and
    # store information about how and when a softlayer_resource
    # should be updated
    class ResourceDefinition
      # the name of the resource this definition is for
      attr_reader :resource_name

      # The block to call in order to update the resource. The
      # return value of this block should be the new value of the
      # resource.
      attr_reader :update_block

      # The block to call to see if the resource needs to be updated.
      attr_reader :should_update_block

      def initialize(resource_name)
        raise ArgumentError if resource_name.nil?
        raise ArgumentError if resource_name.to_s.empty?

        @resource_name = resource_name;
        @update_block = Proc.new { nil; };
        @should_update_block = Proc.new { true; }
      end

      # This method is used to provide behavior for the
      # should_update_ predicate for the resource
      def should_update_if (&block)
        @should_update_block = block
      end

      # This method is used to provide the behavior for
      # the update_! method for the resource.
      def to_update (&block)
        @update_block = block
      end
    end

    module ClassMethods

      # Declares a new softlayer resource and accepts the block
      # in which the should_update and update methods are declared.
      def softlayer_resource (resource_name, &block)
        resource_definition = ResourceDefinition.new(resource_name)

        # allow the block to update the resource definition
        yield resource_definition if block_given?

        # store off the resource definition where we can find it later
        @resource_definitions ||= {};
        @resource_definitions[resource_name] = resource_definition;

        # define a method called "update_<resource_name>!" which calls the update block
        # stored in the resource definition
        update_symbol = "update_#{resource_name}!".to_sym
        define_method(update_symbol, &resource_definition.update_block)

        # define a method called "should_update_<resource_name>?" which calls the
        # should update block stored in the resource definition
        should_update_symbol = "should_update_#{resource_name}?".to_sym
        define_method(should_update_symbol, &resource_definition.should_update_block)

        # define an instance method of the class this is being
        # called on which will get the value of the resource.
        #
        # The getter will take one argument "force_update" which
        # is treated as boolean value. If true, then the getter will
        # force the resource to update (by using its "to_update") block.
        #
        # If the force variable is false, or not given, then the
        # getter will call the "should update" block to find out if the
        # resource needs to be updated.
        #
        getter_name = resource_name.to_sym
        value_instance_variable = "@#{resource_name}".to_sym

        define_method(getter_name) do |*args|
          force_update = args[0] || false

          if force_update || __send__(should_update_symbol)
            instance_variable_set(value_instance_variable, __send__(update_symbol))
          end

          instance_variable_get(value_instance_variable)
        end
      end

      def softlayer_resource_definition(resource_name)
        @resource_definitions[resource_name]
      end
    end

    def self.included(included_in)
      included_in.extend(ClassMethods)
    end
  end
end