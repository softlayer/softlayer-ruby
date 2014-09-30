#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  ##
  # The SoftLayer Gem defines an Object Hierarchy representing entities in
  # an account's SoftLayer environment. This class is the base object class
  # for objects in that hierarchy
  #
  # The SoftLayer API represents entities as a hash of properties. This class
  # stores that hash and allows the use of subscripting to access those properties
  # directly.
  #
  # The class also has a model for making network requests that will refresh
  # the stored hash so that it reflects the most up-to-date information about
  # an entity from the server. Subclasses should override softlayer_properties
  # to retrieve information from the server. Client code should call
  # refresh_details to ask an object to update itself.
  #
  class ModelBase
    # The client environment that this model object belongs to
    attr_reader :softlayer_client

    ##
    # :attr_reader: id
    # The unique identifier of this object within its API service

    # Construct a new model object in the environment of the given client and
    # with the given hash of network data (presumably returned by the SoftLayer API)
    def initialize(softlayer_client, network_hash)
      raise ArgumentError, "A hash is required" if nil == network_hash
      raise ArgumentError, "Model objects must be created in the context of a client" if nil == softlayer_client

      @softlayer_client = softlayer_client
      @softlayer_hash = network_hash

      raise ArgumentError, "The hash used to construct a softlayer model object must have an id" unless has_sl_property?(:id)
      raise ArgumentError, "id must be non-nil and non-empty" unless self[:id]
    end

    ##
    # The service method of a Model object should return a SoftLayer Service
    # that best represents the modeled object.  For example, a Ticket models
    # a particular entity in the SoftLayer_Ticket service.  The particular
    # entity is identified by its id so the Ticket class would return
    #
    #     softlayer_client[:Ticket].object_with_id
    #
    # which is a service which would allow calls to the ticket service
    # through that particular object.
    def service
      raise "Abstract method service in ModelBase was called"
    end

    ##
    # Asks a model object to reload itself from the SoftLayer API.
    #
    # Subclasses should not override this method, rather they should
    # implement softlayer_properties to actually make the API request
    # and return the new hash.
    #
    def refresh_details(object_mask = nil)
      @softlayer_hash = self.softlayer_properties(object_mask)
    end

    ##
    # Returns the value of of the given property as stored in the
    # softlayer_hash. This gives you access to the low-level, raw
    # properties that underly this model object.  The need for this
    # is not uncommon, but using this method should still be done
    # with deliberation.
    def [](softlayer_property)
      self.softlayer_hash[softlayer_property.to_s]
    end

    ##
    # Returns true if the given property can be found in the softlayer hash
    def has_sl_property?(softlayer_property)
      softlayer_hash && softlayer_hash.has_key?(softlayer_property.to_s)
    end

    ##
    # allows subclasses to define attributes as sl_attr
    # sl_attr are attributes that draw their value from the
    # low-level hash representation of the object.
    def self.sl_attr(attribute_symbol, hash_key = nil)
      raise "The sl_attr expects a symbol for the attribute to define" unless attribute_symbol.kind_of?(Symbol)
      raise "The hash key used to define an attribute cannot be empty" if hash_key && hash_key.empty?

      define_method(attribute_symbol.to_sym) { self[hash_key ? hash_key : attribute_symbol.to_s]}
    end

    sl_attr :id

    # When printing to the console using puts, ruby will call the
    # to_ary method trying to convert an object into an array of lines
    # for stdio. We override to_ary to return nil for model objects
    # so they may be printed
    def to_ary()
      return nil;
    end

    protected

    ##
    # Subclasses should implement this method as part of enabling the
    # refresh_details fuctionality The implementation should make a request
    # to the SoftLayer API and retrieve an up-to-date SoftLayer hash
    # representation of this object. That hash should be the return value
    # of this routine.
    #
    def softlayer_properties(object_mask = nil)
      raise "Abstract method softlayer_properties in ModelBase was called"
    end

    ##
    # The softlayer_hash stores the low-level information about an
    # object as it was retrieved from the SoftLayer API.
    attr_reader :softlayer_hash

  end # class ModelBase
end # module SoftLayer
