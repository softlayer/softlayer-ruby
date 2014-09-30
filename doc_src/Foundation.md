# `softlayer_api` Foundation

The Foundation Layer of the `softlayer_api` Gem handles communication, authentication, and direct interaction with the SoftLayer API. The majority of this functionality is embodied in the `SoftLayer::Client` and `SoftLayer::Service` classes. Tools are added to those to support important features of the SoftLayer API such as Object Masks, Result Limits, and Object Filters. This document explains what developers must do to connect to, and interact with, the SoftLayer API using this Gem.

# Getting Started

Getting started with the SoftLayer API is fairly straightforward. There is some key information that you will have to provide to the Gem in order to connect to the SoftLayer API. You provide that information to classes instantiated from the Gem's source and use those instances to make calls into the API.

## Key Information
In order to communicate with the SoftLayer API, the system needs to have three key pieces of information:

* User name &mdash; a user name for the SoftLayer account you wish to work with.
* API key &mdash; API keys are obtained through the SoftLayer web portal.
* Endpoint URL &mdash; A URL to the SoftLayer Endpoint your code would like to communicate with.

The user name is simply the name of one of the user accounts created within your SoftLayer account. While it is possible to use the Master User account we recommend that you create one or more dedicated API user accounts so that you can carefully control account permissions for your API access.

The API key must be generated for the user account you use to access the API. Information on generating API keys can be found in the [Authenticating to the SoftLayer API](http://sldn.softlayer.com/article/Authenticating-SoftLayer-API) article on SLDN under the heading, _Generating Your API Key_. Please remember, your API key is privileged information and you should protect carefully as you would a password.

SoftLayer provides two different endpoint URLs to scripts. One is associated with the public internet and may be accessed from anywhere. These two URLs are available as global variables in the SoftLayer module:

    # The base URL of the SoftLayer API available to the public internet.
    API_PUBLIC_ENDPOINT = 'https://api.softlayer.com/xmlrpc/v3/'

    # The base URL of the SoftLayer API available through SoftLayer's private network
    API_PRIVATE_ENDPOINT = 'https://api.service.softlayer.com/xmlrpc/v3/'

In most cases, you will not have to specify the endpoint URL and the Gem will use the `API_PUBLIC_ENDPOINT` by default.

## Creating a Client

Once you have a username and API key, you need to provide them to the library. An instance of the `SoftLayer::Client` class is responsible the credentials provides them to any object that calls into the network API. One way to create a client is to provide the key information as hash parameters when constructing the client:

    softlayer_client = SoftLayer::Client.new(
      :username => "joecustomer",             # enter your username here
	  :api_key => "feeddeadbeefbadf00d...",   # enter your api key here
	  :endpoint_URL => API_PUBLIC_ENDPOINT
    )

(Note: In the call above, the :endpoint_url is shown explicitly, though in most cases you can leave it off and the `API_PUBLIC_ENDPOINT` will be used by default).

The `SoftLayer::Client` class works through the `SoftLayer::Config` class to discover the communication settings. Config allows developers to use a variety of techniques to provide these settings, for more information see the documentation of that class.

## Obtaining a Service

With a fully configured client, the next step is to obtain an instance of the `SoftLayer::Service` class. Calls to the network SoftLayer API are done through Service objects. The Services of the network SoftLayer API are documented on the [SLDN](http://sldn.softlayer.com) web site.

In this example we will use the `SoftLayer_Account` service. Given the variable `softlayer_client` which is a properly configured Client object, getting the `SoftLayer_Account` service is done as follows:

    account_service = softlayer_client.service_named("Account")

or more succinctly

    account_service = softlayer_client["Account"]

(Please note: Service names are case sensitive and using the prefix `SoftLayer_` in the service name is optional)

## Working with the network API

With a service in hand, calling thorough to the network SoftLayer API is straightforward. Using the `account_service` created above we may call the `getOpenTickets` method in that service directly:

    open_tickets = account_service.getOpenTickets()

The open_tickets variable should receive an array of hashes representing the open tickets for the account that are visible to the user provided to the Client object. As a more complete example, the following script uses the techniques just describe to obtain a list of the open tickets on an account and print the titles of those tickets to the console

    softlayer_client = SoftLayer::Client.new( :username => "joecustomer", api_key => "feeddeadbeefbadf00d...)
    open_tickets = softlayer_client["Account"].getOpenTickets

    open_tickets.each { |ticket_hash| puts ticket_hash["title"] }

This short example shows the essence of working with the Foundation API, you create a client, obtain a service, and make calls to the network SoftLayer API through that service.

## Request Results

Most of the information you get back from the network SoftLayer API at the foundation level is returned as Hashes, or arrays of hashes. These structures are often nested. The keys of the hashes will be strings and use the property name specified in the [SLDN documentation](http://sldn.softlayer.com). The values in the hashes vary depending on the data type of the property represented by the hash key. In the example above, the `getOpenTickets` call returns an array of hashes. Each hash offers information about a single ticket in the account's open ticket list.

The network SoftLayer API provides helpful techniques for limiting and filtering the result set from calls to the network and the `softlayer_api` offers helpful routines for making use of these. Please see the section on Service Helpers below.

## Error reporting

Calls to the network SoftLayer API that result in errors being returned by the server are caught in the XML-RPC layer and passed back to scripts as Exceptions. It is prudent to wrap your calls in exception handling code.

## Troubleshooting

Communication with the SoftLayer servers is handled through the XML-RPC client that is built into the Ruby Core library. As a consequence the network communication is also handled by Core library classes.

One aspect of network communication that the `softlayer_api` relies on the Ruby Core library to provide is SSL certificate authentication. Problems with this authentication often arise if your Ruby environment is not properly configured with SSL root certificates. If you find you are having trouble communicating with the network SoftLayer API, and the error messages point to SSL certificate authentication, please consider a web search using your specific error message as a search string. This will often reveal answers that can help you resolve networking issues your Ruby environment.

Another valuable tool for troubleshooting is the global `$DEBUG` variable. This variable can be set to `true` explicitly in your code, or from the command line by adding the `-d` flag to the ruby command. When set, calls to the XML-RPC library will print both both the request and response sides of server communication. In addition, many of the classes in the `softlayer_api` Gem may respond to this variable and print debugging information to the console.

# Service Helpers

Service helpers are convenient routines that modify the network requests sent to the network API. They allow scripts to take advantage of specific features offered by the network API. To use a service helper, you place a call in the calling chain between a service, and the method that will invoke the network API. For example:

    ticket_service = softlayer_client["Ticket"]
	assigned_user = ticket_service.object_with_id(12345).getAssignedUser()

In this example the method `object_with_id` is a service helper. It instructs the network API to direct the `getAssignedUser` call to the ticket whose `id` is 12345.

It is permissible to invoke more than one helper in a given calling sequence.

Service helpers may also be used to simplify your code as the result of calling a service helper is, itself, an object. Using the example above, if you wished to make multiple calls to the ticket with the `id` 12345 you can store the result of applying the `object_with_id` helper in a variable and create a service proxy with that filter applied. For example:

     my_ticket = softlayer_client["Ticket"].object_with_id(12345)
	 my_ticket.addUpdate({"entry" : "Ticket has been updated"})
	 my_ticket.markAsViewed

The result of calling `object_with_id` on the ticket service is stored in `my_ticket` creating a service proxy that is then used to call both `addUpdate` and `markAsViewed` in the network API. Both of the network calls would be directed at the ticket whose id is 12345 since both the Ticket service, and the applied helper `object_with_id` are part of the proxy.

The remainder of this section looks at the service helpers offered by the `softlayer_api` Gem.

## `object_with_id`

Entities in the SoftLayer environment are uniquely identified by the Service in which they are found, and their object `id`. The `object_with_id` service helper is used to direct a network request to a particular object in the SoftLayer Environment.

Examples of using `object_with_id` to direct a network API request to a particular object (in this case a ticket) are given in the introduction to the Service Helpers section above.

A particular calling sequence should only include one invocation of the `object_with_id` service helper.

## Object Masks

Object Masks offer a way for a script to limit the results of a particular call so that the result includes particular properties of the objects returned by the call. For example, if a problem's solution required the list of open tickets for an account, including each ticket's title and a count of the updates made to the ticket, A script could limit the information returned for each ticket to the title and update count using an object mask:

    softlayer_client["Account"].object_mask("mask[title,updateCount]").getOpenTickets()

The service helper for providing object masks is simply `object_mask`. The parameter to the call is a valid object mask string. More information about the format of object strings may be found in the SLDN documentation on [Object Masks](http://sldn.softlayer.com/article/Object-Masks). In this example, the mask asks the network API to return the `title` and `updateCount` properties of the objects (in this case Tickets) returned by `getOpenTickets`.

Crafting a careful object mask can help your code get exactly the information it needs.

A calling sequence may contain more than one call to the `object_mask` service helper. The masks will be combined and simplified by the library before being passed to the server.

## Result Limits

Result limits are applied to network API calls that return arrays of items. By providing a result limit, your code can ask that only a particular range of items in the array be returned. For example, given an account with 100 open tickets, if you were only interested in 5th through 10th tickets you could request just those tickets using a result limit helper:

    softlayer_client["Account"].result_limit(4,5).getOpenTickets()

The first argument to the `result_limit` helper is the index in the array of the first item you wish to receive. Because indexes are 0 based, to get the 5th element in the call above we have specified and index of 4. The second argument to a `result_limit` call is the number of items you wish to have included in the results. In this case we wanted 5 tickets.

Only one call to the `result_limit` helper should be included in any calling sequence.

## Object Filters

Object Filters ask the server to filter the result set using a set of criteria before returning its results. Unfortunately, at the time of this writing, constructing object filters is not a well documented process. Luckily, the `softlayer_api` Ruby Gem, offers some convenience functionality to help you create simple object filters.  If you want help crafting a particular object filter, we suggest you ask in the [SLDN Forums](https://forums.softlayer.com/forum/softlayer-developer-network) for assistance.

As an example, suppose you wished to obtain a list of all the virtual servers on an account that were in the domain kitchentools.com. To get the list of virtual servers on an account you would use the `SoftLayer_Account` service and call the `getVirtualGuests` method. The filter we wish to apply is based on the `domain` property of the virtual servers being returned. That code would look like this:

    filter = SoftLayer::ObjectFilter.build("domain", "kitchentools.com")
	softlayer_client['Account'].object_filter(filter).getVirtualGuests()

The object filter is applied using the `object_filter` service helper. This method takes a single parameter, the object filter to apply to the network API call.

In order to get the filter we wish to apply, this example uses the `SoftLayer::ObjectFilter#build` method. The first parameter to `build` is the property that we wish our filter based on. The second parameter is a query string, in this case the query string means "objects whose property value exactly matches 'kitchentools.com'". Other query strings possible. For example, if we wanted to select the servers whose domain names end with 'tools.com' we could use the query string '*tools.com'. For more information about query strings, please see the documentation for the `SoftLayer::ObjectFilter#query_to_filter_operation` method.

The `SoftLayer::ObjectFilter#build` routine also allows a block syntax which lets you specify the filter criteria using a very simple Domain Specific Language (DSL).  Here is an example of constructing the same filter `domain` filter from the previous using the block technique:

    filter = SoftLayer::ObjectFilter.build("domain") { is("kichentools.com") }

This filter also asks that the domain exactly match "kitchentools.com".  Other matchers can be found in as the instance methods of the `SoftLayer::ObjectFilterBlockHandler` class.

