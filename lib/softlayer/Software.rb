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
    # :attr_reader:
    # The manufacturer code that is needed to activate a license.
    sl_attr :manufacturer_activation_code, 'manufacturerActivationCode'

    ##
    # :attr_reader:
    # A license key for this specific installation of software, if it is needed.
    sl_attr :manufacturer_license_key,     'manufacturerLicenseInstance'

    ##
    # The manufacturer, name and version of a piece of software.
    sl_dynamic_attr :description do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @description == nil
      end

      resource.to_update do
        description = self.service.getSoftwareDescription
        description['longDescription']
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
        description = self.service.getSoftwareDescription
        description['name']
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
        passwords = self.service.getPasswords
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

    def self.default_object_mask
      {
        "mask(SoftLayer_Software_Component)" => [
                                                 'id',
                                                 'manufacturerActivationCode',
                                                 'manufacturerLicenseInstance'
                                                ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
