#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # Each SoftLayer NetworkStorage instance provides information about
  # a storage product and access credentials.
  #
  # This class roughly corresponds to the entity SoftLayer_Network_Storage
  # in the API.
  #
  class NetworkStorage < ModelBase
    include ::SoftLayer::DynamicAttribute

    ##
    # :attr_reader:
    # A Storage account's capacity, measured in gigabytes.
    sl_attr :capacity,   'capacityGb'

    ##
    # :attr_reader:
    # The date a network storage volume was created.
    sl_attr :created,    'createDate'

    ##
    # :attr_reader:
    # Public notes related to a Storage volume.
    sl_attr :notes

    ##
    # :attr_reader:
    # The password used to access a non-EVault Storage volume.
    # This password is used to register the EVault server agent with the
    # vault backup system.
    sl_attr :password

    ##
    # :attr_reader:
    # A Storage account's type.
    sl_attr :type,       'nasType'

    ##
    # :attr_reader:
    # This flag indicates whether this storage type is upgradable or not.
    sl_attr :upgradable, 'upgradableFlag'

    ##
    # :attr_reader:
    # The username used to access a non-EVault Storage volume.
    # This username is used to register the EVault server agent with the
    # vault backup system.
    sl_attr :username

    ##
    # Other usernames and passwords associated with a Storage volume.
    sl_dynamic_attr :account_password do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @account_password == nil
      end

      resource.to_update do
        account_password = self.service.object_mask(AccountPassword.default_object_mask).getAccountPassword
        AccountPassword.new(softlayer_client, account_password) unless account_password.empty?
      end
    end

    ##
    # A Storage volume's access credentials.
    sl_dynamic_attr :credentials do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @credentials == nil
      end

      resource.to_update do
        self.service.object_mask(NetworkStorageCredential.default_object_mask).getCredentials.collect{|cred| NetworkStorageCredential.new(softlayer_client, cred) }
      end
    end

    ##
    # The network resource a Storage service is connected to.
    sl_dynamic_attr :service_resource do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @service_resource == nil
      end

      resource.to_update do
        NetworkService.new(softlayer_client, self.service.object_mask(NetworkService.default_object_mask).getServiceResource)
      end
    end

    ##
    # The account username and password for the EVault webCC interface.
    sl_dynamic_attr :webcc_account do |resource|
      resource.should_update? do
        #only retrieved once per instance
        @webcc_account == nil
      end

      resource.to_update do
        webcc_account = self.service.object_mask(AccountPassword.default_object_mask).getWebccAccount
        AccountPassword.new(softlayer_client, webcc_account) unless webcc_account.empty?
      end
    end

    ##
    # Add a username/password credential to the network storage instance
    #
    def add_credential(credential_type)
      raise ArgumentError, "The new credential type cannot be nil"   unless credential_type
      raise ArgumentError, "The new credential type cannot be empty" if credential_type.empty?

      new_credential = self.service.object_mask(NetworkStorageCredential.default_object_mask).assignNewCredential(credential_type.to_s)
      
      @credentials = nil

      NetworkStorageCredential.new(softlayer_client, new_credential) unless new_credential.empty?
    end

    ##
    # Assign an existing network storage credential specified by the username to the network storage instance
    #
    def assign_credential(username)
      raise ArgumentError, "The username cannot be nil"   unless username
      raise ArgumentError, "The username cannot be empty" if username.empty?

      self.service.assignCredential(username.to_s)
      
      @credentials = nil
    end

    ##
    # Determines if one of the credentials pertains to the specified username.
    #
    def has_user_credential?(username)
      self.credentials.map { |credential| credential.username }.include?(username)
    end

    ##
    # Updates the notes for the network storage instance.
    #
    def notes=(notes)
      self.service.editObject({ "notes" => notes.to_s })
      self.refresh_details()
    end

    ##
    # Updates the password for the network storage instance.
    #
    def password=(password)
      raise ArgumentError, "The new password cannot be nil"   unless password
      raise ArgumentError, "The new password cannot be empty" if password.empty?

      self.service.editObject({ "password" => password.to_s })
      self.refresh_details()
    end

    ##
    # Remove an existing network storage credential specified by the username from the network storage instance
    #
    def remove_credential(username)
      raise ArgumentError, "The username cannot be nil"   unless username
      raise ArgumentError, "The username cannot be empty" if username.empty?

      self.service.removeCredential(username.to_s)
      
      @credentials = nil
    end

    ##
    # Returns the service for interacting with this network storage through the network API
    #
    def service
      softlayer_client[:Network_Storage].object_with_id(self.id)
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

    ##
    # Updates the password for the network storage credential of the username specified.
    #
    def update_credential_password(username, password)
      raise ArgumentError, "The new password cannot be nil"   unless password
      raise ArgumentError, "The new username cannot be nil"   unless username
      raise ArgumentError, "The new password cannot be empty" if password.empty?
      raise ArgumentError, "The new username cannot be empty" if username.empty?

      self.service.editCredential(username.to_s, password.to_s)

      @credentials = nil
    end

    protected

    def self.default_object_mask
      {
        "mask(SoftLayer_Network_Storage)" => [
                                              'capacityGb',
                                              'createDate',
                                              'id',
                                              'nasType',
                                              'notes',
                                              'password',
                                              'upgradableFlag',
                                              'username'
                                             ]
      }.to_sl_object_mask
    end
  end
end #SoftLayer
