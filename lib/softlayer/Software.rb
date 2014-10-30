#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # Each SoftLayer Software instance provides information about software
  # installed on a specific piece of hardware.
  #
  # This class roughly corresponds to the entity SoftLayer_Software_Component
  # in the API.
  #
  class Software < ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # The manufacturer, name and version of a piece of software.
    sl_dynamic_attr :description do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @description == nil
      end

      resource.to_update do
        description = self.service.object_mask("mask[softwareDescription.longDescription]").getObject
        description['softwareDescription']['longDescription']
      end
    end

    ##
    # The name of this specific piece of software. 
    sl_dynamic_attr :name do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @name == nil
      end

      resource.to_update do
        name = self.service.object_mask("mask[softwareDescription.name]").getObject
        name['softwareDescription']['name']
      end
    end

    ##
    # Username/Password pairs used for access to this Software Installation.
    sl_dynamic_attr :passwords do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @passwords == nil
      end

      resource.to_update do
        passwords = self.service.object_mask("mask[passwords]").getObject['passwords']
        passwords.collect { |password_data| SoftwarePassword.new(softlayer_client, password_data) }
      end
    end

    ##
    # Returns the service for interacting with this software component through the network API
    #
    def service
      softlayer_client[:Software_Component].object_with_id(self.id)
    end

    protected

    def self.default_object_mask(root)
      "#{root}[id,hardware.id,passwords,softwareDescription[longDescription,name],virtualGuest.id]"
    end
  end
end #SoftLayer
