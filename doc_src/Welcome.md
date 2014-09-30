# Welcome

The `softlyer_api` Ruby Gem provides a convenient way to call into the SoftLayer API from the Ruby programming language. This is accomplished using the XML-RPC interface provided by SoftLayer and the XMLRPC client built into the core Ruby language.

For more information about the SoftLayer API, and the routines and data structures it offers should visit the [SoftLayer Developer Network (SLDN) website](http://sldn.softlayer.com).

This document is written for Ruby developers who wish to interact with their SoftLayer accounts through Ruby scripts. SoftLayer also offers a command line tool for performing common tasks. If prefer to use that tool, we invite you to look into the [command line interface](https://softlayer-python.readthedocs.org/en/latest/cli.html) that is part of the [git](http://github.com/softlayer/softlayer-python) project.

This documentation is also written for Ruby developers who wish to contribute to the `softlayer_api` Gem. The Gem is a work in progress. We welcome the support of the SoftLayer development community to improve the Gem. The project is open source and we hope that source will serve as a useful library, stand as sample code to assist exploration, and serve as an opportunity for developers to shape it for both those needs.

The primary repository for the Gem's source code is the [softlayer-ruby](http://github.com/softlayer/softlayer-ruby) github project.

# Overview

These Ruby language bindings allow access to the SoftLayer API on two different levels. A Foundation layer for low-level interaction with the SoftLayer API, and an abstraction layer that simplifies and isolates scripts from some of the details found in the Foundation.

The Foundation layer, makes use of the [XMLRPC client](http://www.ruby-doc.org/stdlib-2.1.2/libdoc/xmlrpc/rdoc/XMLRPC/Client.html) which is part of the Core library of Ruby itself. This foundation is embodied primarily in the `SoftLayer::Client` and `SoftLayer::Service` classes. Requests are made, and responses retrieved using fundamental Ruby types such as Hashes, Arrays, Strings, and Integers.

The Model layer is built atop the foundation as object class hierarchy. The class hierarchy models the  structures found in the SoftLayer environment using the object-oriented features of Ruby. It does this to abstract out some of the implementation detail that a developer would commonly have to work with to communicate with SoftLayer through the foundation layer.

The Model layer is by no means complete; quite to the contrary it is in its infancy and we believe that much of the development effort in the Gem will focus on incorporating new models into this layer. Because it is incomplete, however, we have put some effort into bridges from the functionality of the model, down to the lower level foundation, without trouble. Also, as a result of this, developers interested in using the Model layer should also should familiarize themselves with the Foundation.

All developers should continue their exploration of the `softlayer_api` gem by examining the Foundation documentation. Clients that wish to make use of the abstractions provided in the object hierarchy may continue their exploration by looking at the Model Layer documentation. Developers who wish to expand the models found in the `softlayer_api` Gem should read the [Contribution Guide](ContributionGuide_md.html)