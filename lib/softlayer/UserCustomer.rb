#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # Each SoftLayer UserCustomer instance provides information
  # relating to a single SoftLayer customer portal user
  #
  # This class roughly corresponds to the entity SoftLayer_User_Customer
  # in the API.
  #
  class UserCustomer < ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader:
    # A portal user's secondary phone number.
    sl_attr :alternate_phone,  'alternatePhone'

    ##
    # :attr_reader:
    # The date a portal user's record was created.
    sl_attr :created,          'createDate'

    ##
    # :attr_reader:
    # The portal user's display name.
    sl_attr :display_name,     'displayName'

    ##
    # :attr_reader:
    # A portal user's email address.
    sl_attr :email

    ##
    # :attr_reader:
    # A portal user's first name.
    sl_attr :first_name,       'firstName'

    ##
    # :attr_reader:
    # A portal user's last name.
    sl_attr :last_name,        'lastName'

    ##
    # :attr_reader:
    # The date a portal user's record was last modified.
    sl_attr :modified,         'modifyDate'

    ##
    # :attr_reader:
    # A portal user's office phone number.
    sl_attr :office_phone,     'officePhone'

    ##
    # :attr_reader:
    # The expiration date for the user's password.
    sl_attr :password_expires, 'passwordExpireDate'

    ##
    # :attr_reader:
    # The date a portal users record's last status change.
    sl_attr :status_changed,   'statusDate'

    ##
    # :attr_reader:
    # A portal user's username.
    sl_attr :username

    ##
    # A portal user's additional email addresses.
    # These email addresses are contacted when updates are made to support tickets.
    sl_dynamic_attr :additional_emails do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @additional_emails == nil
      end

      resource.to_update do
        additional_emails = self.service.getAdditionalEmails
        additional_emails.collect { |additional_email| additional_email['email'] }
      end
    end

    ##
    # A portal user's API Authentication keys.
    # There is a max limit of two API keys per user.
    sl_dynamic_attr :api_authentication_keys do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @api_authentication_keys == nil
      end

      resource.to_update do
        self.service.object_mask("mask[authenticationKey,ipAddressRestriction]").getApiAuthenticationKeys
      end
    end
    
    ##
    # The external authentication bindings that link an external identifier to a SoftLayer user.
    sl_dynamic_attr :external_bindings do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @external_bindings == nil
      end

      resource.to_update do
        external_bindings = self.service.object_mask(UserCustomerExternalBinding.default_object_mask).getExternalBindings
        external_bindings.collect { |external_binding| UserCustomerExternalBinding.new(soflayer_client, external_binding) }
      end
    end

    ##
    # Returns the service for interacting with this user customer through the network API
    #
    def service
      softlayer_client[:User_Customer].object_with_id(self.id)
    end

    protected

    def self.default_object_mask
      {
        "mask(SoftLayer_User_Customer)" => [
                                            'alternatePhone',
                                            'createDate',
                                            'displayName',
                                            'email',
                                            'firstName',
                                            'id',
                                            'lastName',
                                            'modifyDate',
                                            'officePhone',
                                            'passwordExpireDate',
                                            'statusDate',
                                            'username'
                                           ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
