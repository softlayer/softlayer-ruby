# SoftLayer API Client for Ruby

The SoftLayer API Client for Ruby is a library for connecting to and calling the routines of [The SoftLayer API](http://sldn.softlayer.com/article/The_SoftLayer_API) from the [Ruby](http://www.ruby-lang.org) programming language.

<div id="note" style="margin: 1em; padding: 0.5em; background-color: #fcfcfc; border: 1px solid black">
	*Important Note*

	If you are arriving at this build from verison 1.0 of the `softlayer_api` gem, you will probably have to change some of your existing scripts. Please see <a href="#label-What%27s+New">What's New<a> for details.
</div>

## Overview

The client invokes methods in the API using XML-RPC as a transport mechanism. XML-RPC is handled using `XMLRPC` classes from the Ruby core library.

To make calls to the Ruby API through the client you will create an instance of the `SoftLayer::Client` class, optionally identifying an API endpoint, and providing authentication information in the form of a username and API key. From the client you can obtain various `SoftLayer::Service` instances and use them to invoke the methods of the API. Results of those calls are communicated from the server to the client as XML, then decoded and returned to you as standard Ruby objects like Hashes, Arrays, and Strings.

Source code for daily builds of this Gem can be found on the [SoftLayer github public repositories](http://github.com/softlayer/). The latest release version of the Gem is available from the Ruby gem system. (see Installation below)

Should you encounter problems with the client, please contact us in the [SoftLayer Developer Network forums](http://forums.softlayer.com/forum/softlayer-developer-network) or open a support ticket in the SoftLayer customer portal.

## Requirements

The Ruby client has been tested using a wide variety of Ruby implementations including Ruby version 1.9.2, 2.0, and 2.1. It has also been tested on JRuby running in 1.9 mode.

A network connection is required, and a valid SoftLayer API username and api key are required to call the SoftLayer API. A connection to the SoftLayer private network is required to connect to SoftLayer's private network API endpoints.

## What's New

The softlayer_api gem no longer supports Ruby 1.8.x

**Version 2.1** of `softlayer_api` builds an object model of SoftLayer clases on top of the low-level SoftLayer API calls. The object model provides a high-level interface to the elements within the SoftLayer environment and encapsulates some of the details of the "raw" SoftLayer API.

With this first release, the Object Model provides classes for the SoftLayer Account, Bare Metal and Virutal servers, and Tickets. The model also provides classes to help you place orders for both Bare Metal and Virtual Servers. The class structure is not meant to be comprehensive.  Our goal is to provide a simple API for performing common operations.

Interface documentation for the new object hierarchy is available in the gem's source. More comprehensive documentation including a design guide for new clases and a contribution guide for developers will be added in the future.

**Version 2.0** of the `softlayer_api` gem changes the protocol used to communicate with the SoftLayer API from REST to XML-RPC. This change alone should not require any changes to scripts written to the version 1.0 gem. However there are two new behaviors which will require existing version 1.0 scripts to change:

* Object Masks are now sent to the server using the [Extended Object Mask Format](http://sldn.softlayer.com/article/Object-Masks).
* Result limits are now specified using a single call rather than requiring two

The gem now allows you to specify your SoftLayer username and API key through a config file. See [Providing authentication in a config file](#config_authorization) for more information.

### XML-RPC

In the broad view of the SoftLayer API, when sending requests to the server, an API client may use [SOAP](http://sldn.softlayer.com/article/SOAP), [XML-RPC](http://sldn.softlayer.com/article/XML-RPC), or [REST](http://sldn.softlayer.com/article/REST). Previous versions of the SoftLayer API Gem used REST to communicate with the server. This version uses XML-RPC. Adopting the XML-RPC transport mechanism allows the Gem to take adavantage of features of the API that are not available through the REST interface.

### Extended Object Masks

In previous versions of the SoftLayer Gem the `object_mask` call modifier accepted Ruby structres like Arrays and Hashes and would do its best to construct Object Masks from them. `object_mask` now expects masks to be passed as strings in the [Object Mask](http://sldn.softlayer.com/article/Object-Masks) format and passes them through to the API for processing. If you are using `object_mask`, you will probably have to change your existing scripts.

The Gem extends the Ruby `Hash` class with a method, `to_sl_object_mask`, which can help with the conversion between masks made of structured objects and the string format. This method, however, must be called explicitly. Here is an example of calling `to_sl_object_mask`:

    mask_hash = { "mask" => ["id", {"assignedUser" => ["id", "username"]}, "createDate"],
      "mask(SoftLayer_Hardware_Server)" => ["id", "bareMetalInstanceFlag"] }
    mask_string = mask_hash.to_sl_object_mask
    # mask_string is "[mask[id,assignedUser[id,username],createDate],mask(SoftLayer_Hardware_Server)[id,bareMetalInstanceFlag]]"

### Result Limits

In previous versions of the SoftLayer API Gem, result limits were specified using two API filters:

    account_service.result_offset(3).result_limit(5).getOpenTickets  # this is the "old way" of specifying a result limit

These two API filters have been combined into a single result limits filter:

    account_service.result_limit(3, 5).getOpenTickets # this is the "new way" of supplying a result limit

## Installation

The Ruby client is available as the `softlayer_api` Ruby gem. On most systems, the command:

    gem install softlayer_api

installs the gem and makes it available to Ruby scripts. Where the gem is installed on your computer will depend on your particular distribution of Ruby. Refer to the gem documentation for your distribution for more information.

## Usage

To begin using the Ruby client, you will have to create an instance of the `SoftLayer::Client`. From the Client you must obtain `SoftLayer::Service` objects corresponding to each of the [API Services](http://sldn.softlayer.com/reference/services) that your code wants to call. To create the client instance, you will have to provide information that the library will use to authenticate your account with the API servers.

### Authentication

That instance will have to know your [API authentication information](http://sldn.softlayer.com/article/Authenticating_to_the_SoftLayer_API) consisting of your account username and API key. In addition, you will have to select an endpoint, the web address the client will use to contact the SoftLayer API. You may provide this information in a configuration file, through global variables, or by passing them to the constructor.

## Providing authentication in a config file

The Ruby client will look for a configuration file that can provide the username and api_key for requests. A sample configuraiton file looks like this:

    [softlayer]
    username = joeusername
    api_key = DEADBEEFBADF00D

It is important that the config file declare the section "softlayer". The keys accepted in that section are `username`, `api_key`, and `endpoint_url`. You will have to provide an explicit endpoint url, for example, if you want to use the SoftLayer private network API endpoint.

The client will look for configuration files in your home directory under the name ".softlayer" or in the directory `/etc/softlayer.conf`

#### Providing authentication information through Globals

The SoftLayer Ruby Client makes use of three global variables, in the `SoftLayer` name space that can be used to provide conneciton information. Since version 2.0 of the gem, these globals have become less useful as the Client is a much better repository for the connection and authentication information.  However, the globals are still supported for backward compatibility. Those globals are:

<table style="position:relative;left:2em;width:80%;margin:2em">
<tr><td style="vertical-align:baseline;width:35%"><b>$SL_API_USERNAME</b></td><td>A string used as the default username</td></tr>
<tr><td style="vertical-align:baseline;width:35%"><b>$SL_API_KEY</b></td><td>A string used as the default API key</td></tr>
<tr><td style="vertical-align:baseline;width:35%"><b>$SL_API_BASE_URL</b></td><td>A string used as the default value for the endpoint_url. This variable is initialized with the constant API_PUBLIC_ENDPOINT</td></tr>
</table>

In addition to the globals, the `SoftLayer` namespace defines two constants representing the endpoints for the SoftLayer API on the private and public networks:

<table style="position:relative;left:2em;width:80%;margin:2em">
<tr><td style="vertical-align:baseline;width:35%"><b>API_PUBLIC_ENDPOINT</b></td><td>A constant containing the base address for the public network XML-RPC endpoint of the SoftLayer API - https://api.softlayer.com/xmlrpc/v3/<td></tr>
<tr><td style="vertical-align:baseline;width:35%"><b>API_PRIVATE_ENDPOINT</b></td><td>A constant containing the base address for the private network XML-RPC endpoint of the SoftLayer API - https://api.service.softlayer.com/xmlrpc/v3/<td></tr>
</table>

For more information about the two networks see [Choosing_the_Public_or_Private_Network](http://sldn.softlayer.com/article/The_SoftLayer_API#Choosing_the_Public_or_Private_Network). You can change the default endpoint URL by setting the global variable `$SL_API_BASE_URL` to either of these two values.

Here is an example of using these globals to create a client:

    $SL_API_USERNAME = "joeusername";
    $SL_API_KEY = "omitted_for_brevity"

    client = SoftLayer::Client.new()
    account_service = client.service_named("Account")

Note that the endpoint URL is not specified. The default endpoint URL is set to the `API_PUBLIC_ENDPOINT`

#### Providing authentication information through the Constructor

You can provide the authentication information needed by a `Client` object as hash arguments in the constructor. The keys used in the hash arguments are symbols whose values should be strings:

<table style="position:relative;left:2em;width:80%;margin:2em">
<tr><td style="vertical-align:baseline;width:30%">:username</td><td>The username used to authenticate with the server.</td></tr>
<tr><td style="vertical-align:baseline;width:30%">:api_key</td><td>The API key used to authenticate with the server.</td></tr>
<tr><td style="vertical-align:baseline;width:30%">:endpoint_url</td><td>The endpoint address that will receive the method calls.</td></tr>
</table>

Here is an example, analogous to the one for global variables, which provides the username and API key as hash arguments. This example also changes the endpoint with the `:endpoint_url` symbol so that services created with this client will use the API on the SoftLayer Private Network:

    client = SoftLayer::Client.new(:username => "joeusername",
        :api_key => "omitted_for_brevity",
        :endpoint_url => API_PRIVATE_ENDPOINT)
    account_service = client.service_named("Account")

### Calling Service Methods

With an instance of `SoftLayer::Service` in hand, you can call the methods provided by that service. Calling a API method on a service is as easy as calling a Ruby method on the service object. For example, given the `account_service` objects created above, a call to get a list of the open tickets on an account using the `SoftLayer_Account` service's `getOpenTickets` method would look like this:

    open_tickets = account_service.getOpenTickets

If the method requires arguments, you can supply them as arguments to the method you're calling on the service object. The arguments should be arguments that XML-RPC can encode into XML. Generally this means your argument should be hashes, arrays, strings, numbers, booleans, or nil.

Here is an example of calling the `createStandardTicket` method on a ticket service. This example also uses the "bracket" syntax on a client to obtain the Ticket service:

    #authentication information will be found in the global variables
    client = SoftLayer::Client.new()
    ticket_service = client['Ticket']
    new_ticket = ticket_service.createStandardTicket(
      {
        "assignedUserId" => my_account_id,
        "subjectId" => 1022,
        "notifyUserOnUpdateFlag" => true
      },
      "This is a test ticket created from a Ruby client")

#### Identifying Particular Objects

Some method calls in the SoftLayer API are made on particular objects, rather than on the services themselves. These objects, however, are always obtained by a service. To call a method on a particular object you can chain a call to `object_with_id` onto the service that provides the object in question. `object_with_id` takes one argument, the object id of the object you are interested in. For example, if you were interested in getting the Ticket with a ticket id of 123456 you could so so by calling:

     ticket_of_interest = ticket_service.object_with_id(123456).getObject

The `object_with_id` call returns an object that you can use as a reference to a particular object through the service. This allows you to reuse that object multiple times without having to repeatedly tack `object_with_id` on to all your requests. For example, if you want to find a ticket with the id 98765 and add an update to it if it's assigned to user 123456, you might write code like this:

    begin
        ticket_ref = ticket_service.object_with_id(98765)
        ticket = ticket_ref.object_mask("mask.assignedUserId").getObject
        if ticket['assignedUserId'] == 123456
            updates = ticket_ref.addUpdate({"entry" => "Get to work on these tickets!"})
        end
    rescue Exception => exception
        puts "An error occurred while updating the ticket: #{exception}"
    end

The code creates a variable named `ticket_ref` which refers to ticket 98765 through the tickets_service. This `ticket_ref` is used with an `object_mask` to retrieve the ticket and, if the ticket meets the conditional requirement, that same `ticket_ref` is reused to add an update to the ticket.

#### Adding an Object Mask

If you wish to limit the volume of information that the server returns about a particular object, you can use an Object Mask to indicate exactly which attributes you are interested in. To provide an Object Mask you simply insert a call to `object_mask` in the call chain for the method you are invoking.

The arguments to `object_mask` must strings. Each string should be a well defined Object Mask as defined in the [SLDN documentation](http://sldn.softlayer.com/article/Object-Masks).

To look at some examples, consider the following object from the server. It has four properties: `id`, `title`, `createDate` and `modifyDate`. It also has an entity, `assignedUser`. The `assignedUser` entity has three properties: `id`, `username`, and `health`.

    {
        "id"=>1736473,
        "title"=>"VM Polling Failure - unable to login",
        "createDate"=>"2010-04-22T00:12:36-05:00",
        "modifyDate"=>"2010-06-09T06:44:18-05:00"
        "assignedUser"=> {
            "id"=>14
            "username"=>"AlfredQHacker",
            "health"=>"Fantastic"
        },
    }

If we were making a request to the server to retrieve this object, or an array of such objects, we might want to limit the response so that it contains just the `id` fields:

    an_api_service.object_mask("mask.id").getObject
    #=> {"id"=>1736473}


If we want more than one property back from the server the call to `object_mask` can identify multiple properties as separate argumnents:

    an_api_service.object_mask("mask[id,createDate]").getObject
    #=> {"id"=>1736473, "createDate"=>"2010-04-22T00:12:36-05:00"}

If we ask for the `assignedUser` we get back that entire entity:

    an_api_service.object_mask("mask.assignedUser").getObject
    #=> {"assignedUser"=> {"id"=>14, "username"=>"AlfredQHacker", "health"=>"Fantastic"}}

However, we may not be interested in the entire assigned user entity, we may want to get just the id of the assigned user: 

    an_api_service.object_mask("mask[assignedUser.id]").getObject
    #=> {"assignedUser"=>{"id"=>14}}

We can identify a particular set of attributes we are interested in by combining Object Mask forms:

    an_api_service.object_mask("mask[assignedUser[id,health]]").getObject # retrieving multiple properties
    #=> {"assignedUser"=>{"id"=>14, "health"=>"Fantastic"}}

Object masks are sent to the server and applied on the server side. Errors in the object mask format will lead to exceptions being thrown by the SoftLayer API. By carefully choosing an Object Mask, you can limit amount of information transferred from the server which may improve bandwidth and processing time.

You `object_with_id` should only be called once in any calling sequence. You may call `object_mask` multiple times, but the server may generate a warning if the Object Masks ask for duplicate properties of some object.

## Author

This software is written by the SoftLayer Development Team [sldn@softlayer.com](mailto:sldn@softlayer.com).

Please join us in the [SoftLayer Developer Network forums](http://forums.softlayer.com/forum/softlayer-developer-network)

## Copyright

This software is Copyright (c) 2010-2014 [SoftLayer Technologies, Inc](http://www.softlayer.com/). See the bundled LICENSE.textile file for more information.
