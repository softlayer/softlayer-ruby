module SoftLayer
  module ModelResource

    # ResourceDefinition inner class used to collect and
    # store information about how and when a resource
    # should be updated (presumably by loading it from the
    # network)
    class ResourceDefinition
      # the name of the resource this definition is for
      attr_reader :resource_name

      # How often should the resource be re-loaded (expressed in seconds)
      attr_reader :refresh_interval

      # The block to call in order to update the resource.  The
      # return value of this block should be the new value of the
      # resource.  The block should take one argument, that argument
      # is the owner of the resource.
      attr_reader :update_block

      def initialize(resource_name)
        raise ArgumentError if resource_name.nil?
        raise ArgumentError if resource_name.to_s.empty?

        @resource_name = resource_name;
        @refresh_interval = 0
        @update_block = Proc.new { nil; };
      end

      def refresh_every (num_seconds)
        @refresh_interval = num_seconds;
      end

      def update (&block)
        @update_block = block;
      end
    end

    module ClassMethods
      def softlayer_resource (resource_name, &block)
        resource_definition = ResourceDefinition.new(resource_name)

        # allow the block to update the resource definition
        yield resource_definition if block_given?

        # store off the resource definition where we can find it later
        @resource_definitions ||= {};
        @resource_definitions[resource_name] = resource_definition;

        # define an instance method of the class this is being
        # called on which will get the value of the resource.
        getter_name = resource_name.to_sym
        value_instance_variable = "@#{resource_name}".to_sym
        updated_instance_variable = "@#{resource_name}_updated".to_sym
        updated_method_name = "updated_#{resource_name}"

        define_method(getter_name) do |*args|
          force_update = args[0] || false

          # set the updated instance variable to antiquity if it hasn't been defined yet
          instance_variable_set(updated_instance_variable, Time.at(0)) if !instance_variable_defined?(updated_instance_variable)

          # grab the resource definition and see if enough time has passed that
          # we should update the resource value (or update it force_update is true)
          resource_definition = self.class.softlayer_resource_definition(resource_name)
          last_update = instance_variable_get(updated_instance_variable)

          if force_update || ((Time.now - last_update) > resource_definition.refresh_interval)
            instance_variable_set(value_instance_variable, __send__(updated_method_name.to_sym))
            instance_variable_set(updated_instance_variable, Time.now)
          end
          
          instance_variable_get(value_instance_variable)
        end
        
        # define a method called "updated_<resource_name>" which calls the update block
        # from the resource definition
        define_method(updated_method_name, &resource_definition.update_block)
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
