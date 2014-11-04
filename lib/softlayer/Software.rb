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
    # Adds specified username/password combination to current software instance
    #
    def add_user_password(username, password, options = {})
      raise ArgumentError, "The new password cannot be nil"   unless password
      raise ArgumentError, "The new username cannot be nil"   unless username
      raise ArgumentError, "The new password cannot be empty" if password.empty?
      raise ArgumentError, "The new username cannot be empty" if username.empty?

      raise Exception, "Cannot add username password, a Software Password already exists for the provided username" if self.has_user_password?(username.to_s)

      add_user_pw_template = {
        'softwareId' => self['id'].to_i,
        'password'   => password.to_s,
        'username'   => username.to_s
      }

      add_user_pw_template['notes'] = options['notes'].to_s if options.has_key?('notes')
      add_user_pw_template['port']  = options['port'].to_i  if options.has_key?('port')

      softlayer_client[:Software_Component_Password].createObject(add_user_pw_template)

      @passwords = nil
    end

    ##
    # Deletes specified username password from current software instance
    #
    #
    # This is a final action and cannot be undone.
    # the transaction will proceed immediately.
    #
    # Call it with extreme care!
    def delete_user_password!(username)
      user_password = self.passwords.select { |sw_pw| sw_pw.username == username.to_s }

      unless user_password.empty?
        softlayer_client[:Software_Component_Password].object_with_id(user_password.first['id']).deleteObject
        @passwords = nil
      end
    end

    ##
    # Returns whether or not one of the Software Passowrd instances pertains to the specified user
    #
    def has_user_password?(username)
      self.passwords.map { |sw_pw| sw_pw.username }.include?(username)
    end

    ##
    # Returns the service for interacting with this software component through the network API
    #
    def service
      softlayer_client[:Software_Component].object_with_id(self.id)
    end

    ##
    # Make an API request to SoftLayer and return the latest properties hash
    # for this object.
    #
    def softlayer_properties(object_mask = nil)
      my_service = self.service

      if(object_mask)
        my_service = my_service.object_mask(object_mask)
      else
        my_service = my_service.object_mask(self.class.default_object_mask)
      end

      my_service.getObject()
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
