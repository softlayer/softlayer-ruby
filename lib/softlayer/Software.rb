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
    # Username/Password pairs used for access to this Software Installation.
    sl_dynamic_attr :passwords do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @passwords == nil
      end

      resource.to_update do
        self['passwords'].collect { |password_data| SoftwarePassword.new(softlayer_client, password_data) }
      end
    end

    ##
    # The manufacturer, name and version of a piece of software.
    #
    def description
      self['softwareDescription']['longDescription']
    end

    ##
    # The name of this specific piece of software. 
    #
    def name
      self['softwareDescription']['name']
    end

    ##
    # Returns the service for interacting with this software component through the network API
    #
    def service
      softlayer_client[:Software_Component].object_with_id(self.id)
    end

    protected

    def self.default_object_mask
      {
        "mask(SoftLayer_Software_Component)" => [
                                                 'id',
                                                 'hardware.id',
                                                 'passwords',
                                                 'softwareDescription[longDescription,name]',
                                                 'virtualGuest.id'
                                                ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
