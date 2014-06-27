# `softlayer_api` Model Layer

The Model Layer builds upon the Foundation layer and offers abstractions of the entities in the SoftLayer environment. For example, computing assets in the SoftLayer environment are found in two separate services [SoftLayer_Hardware](http://sldn.softlayer.com/reference/services/SoftLayer_Hardware) and [SoftLayer_Virtual_Guest](http://sldn.softlayer.com/reference/services/SoftLayer_Virtual_Guest). The Model Layer, however, creates a Server abstraction on top of those services. By doing so, a Ruby script can work with an instance of the SoftLayer::Server object class, send that object the "cancel!" message, and trust the underlying object framework to route the message to the appropriate service and routine within the network API.

The Model Layer is not meant to be complete. In fact, it models just a few key elements of the SoftLayer environment at this point, however we hope the Model Layer will grow and encompass more of the entities found in the API over time. In the interim, however, the current framework includes some convenient bridges that allow Ruby scripts to move from working with the abstractions of the Model Layer to the lower-level routines of the Foundation API easily.

The details of the individual classes that for the object class hierarchy of the Model layer are included in the API documentation. This document will discuss some of the general features of the Model Layer and the bridges that are in place to help code move between the Foundation and Model Layers.

# The ModelBase Class

The ModelBase is the abstract base class of object class hierarchy that forms the Model Layer of the `softlayer_api` Gem. An instance of ModelBase represents a single entity within the SoftLayer API.

In the Foundation layer, SoftLayer entities are represented as a Ruby hash whose keys and values are the are property names and property values of the entity. In the Model Layer, SoftLayer entities are represented by instances of the concrete subclasses of the Model Base class.

In implementation terms, an instance of the ModelBase class (or more accurately and instance of a concrete subclass of the ModelBase class) encapsulates the hashes of the Foundation layer defines the attributes and operations that form a convenient model for working with the underlying entity.

Here we will discuss the general features that all concrete subclasses of ModelBase share.

## Initializing Instances

The initializer for classes in the ModelBase hierarchy are declared:

    def initialize(softlayer_client, network_hash)
      …
    end

The first argument is the client that the object may use to make requests to the network API. The second is the `network_hash`, the hash representation of the entity as returned by the network API.

The hash used to initialize an instance of ModelBase *must* contain a key, `id`, whose value is the `id` of the SoftLayer entity that the object model instance will represent. Correspondingly, the ModelBase class defines the `id` as having the same value as the `id` property in the network hash.

## Updating Instances from the Network

If you wish to ask an instance of ModelBase to update itself with the latest information from the SoftLayer network API, you may call the `refresh_details` method defined in the ModelBase class. This method is likely to make one or more calls through to the network API and will, consequently, incur the overhead of network communication. (Note: subclasses should not override `refresh_details` but should, instead, override the `softlayer_properties` method. Correspondingly, the softlayer_properties method is an implementation detail of ModelBase and is not intended to be called by outside code.)

## Bridging to the Foundation layer

Because the Model Layer offers limited coverage of the vast expanse of functionality found in the network API, it is often necessary to move from an object instance in the Model Layer to the implementation details from the Foundation layer. The Model Base class includes several features to help bridge the between layers gap.

### Accessing Properties

The ModelBase class defines the subscript operator (`[]`) to accept a property name as a string and return that property of the underlying hash. For example, given a ticket, represented by an instance of the SoftLayer::Ticket model layer class, there is no Model Layer representation corresponding to the `serviceProvider` property of the SoftLayer ticket entity. However, the subscript operator can be used to access that property from a model layer object:

    ticket = SoftLayer::Ticket.ticket_with_id(123456)
	service_provider = ticket['serviceProvider']

In this case we ask the ticket for the value of the `serviceProvider` property. Note that the argument to the subscript operator is a string containing the property name.

This technique can only return values stored in the `softlayer_hash` encapsulated in the ModelBase class. Many classes in the Model Layer limit the information retrieved from the network (using object masks) to a subset of the full set of properties available through the network API. Scripts can check whether or not a given property is included in the underlying hash by calling the `has_sl_property?` method of ModelBase.

### Calling Network API routines

Where possible, each subclass of ModelBase should provide a `service` attribute. The value of that attribute should be an instance of SoftLayer::Service, with Service Helpers applied, suitable for addressing the SoftLayer entity represented by the object through the network API.  For example, consider an instance of the Model Layer class SoftLayer::Ticket which represents a service ticket within the network API. The Ticket class defines the `service` attribute of that instance to be the value:

    self.softlayer_client['Ticket'].object_with_id(self.id)

because this service object includes `object_with_id` service helper the result can be used to call through to the network API and that call will be directed at the SoftLayer_Ticket entity with the same id as the model object.  For example:

    ticket_object.service.getAttachedFile(file_id)

calls the `getAttachedFile` method of the SoftLayer_Ticket service which is not yet available in the SoftLayer::Ticket object model class.

## The rest of the model

The ModelBase class is literally the tip of the iceberg for the Model Layer, the bulk of functionality found in this layer is defined by concrete classes like SoftLayer::Ticket and SoftLayer::BareMetalServer, and in other abstract base classes like SoftLayer::Server.  To understand the model presented by each class, we invite you to explore the API documentation.