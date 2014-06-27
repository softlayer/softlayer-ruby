[![Gem Version](https://badge.fury.io/rb/softlayer_api.svg)](http://badge.fury.io/rb/softlayer_api)
[![Build Status](https://travis-ci.org/softlayer/softlayer-ruby.svg?branch=master)](https://travis-ci.org/SLsthompson/softlayer-ruby)
[![Coverage Status](https://coveralls.io/repos/softlayer/softlayer-ruby/badge.png?branch=master)](https://coveralls.io/r/SLsthompson/softlayer-ruby?branch=master)

# SoftLayer API for Ruby

The softlayer-ruby project creates a [Ruby Gem](http://rubygems.org/gems/softlayer_api) which provides language bindings to the [SoftLayer API](http://sldn.softlayer.com/article/The_SoftLayer_API) for the [Ruby](http://www.ruby-lang.org) programming language.

The heart of the project a foundation layer (represented by the Client and Service classes) that allows SoftLayer customers to make direct calls to the SoftLayer API. The Gem also builds a object heirarchy on top of that foundation which provides an abstract model which insulates scripts from direct dependency on the low-level details of the SoftLayer API.

More comprehensive documentation on using the `softlayer_api` Gem, and contributing to the project, may be found by cloning this project and generating the documentation.

## Generating Documentation

Once you have cloned the project, from the main project directory you can generate documentation by installing the bundle and using `rake`:

    $ cd softlayer-ruby
    $ bundle install
    $ bundle exec rake rdoc

This will create a new folder named `doc` inside of the project source and populate it with project documentation. You may then open the documentation file `doc/index.html` in your browser to begin exploring the documentation.

## Author

This software is written by the SoftLayer Development Team [sldn@softlayer.com](mailto:sldn@softlayer.com).

Please join us in the [SoftLayer Developer Network forums](http://forums.softlayer.com/forum/softlayer-developer-network)

# Copyright and License

The `softlayer_api` Ruby Gem and it's source files are Copyright &copy; 2010-2014 [SoftLayer Technologies, Inc](http://www.softlayer.com/).  The software is provided under an MIT license. Details of that license can be found in the embedded LICENSE.md file.

#Warranty

This software is provided “as is” and without any express or implied warranties, including, without limitation, the implied warranties of merchantability and fitness for a particular purpose.
