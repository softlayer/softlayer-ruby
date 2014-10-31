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
    # Returns the service for interacting with this network storage through the network API
    #
    def service
      softlayer_client[:Network_Storage].object_with_id(self.id)
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
