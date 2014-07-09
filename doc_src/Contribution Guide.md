# Contribution Guide

The `softlayer_api` Ruby Gem is an open source project and the developers who use it have an opportunity to tailor its direction. Here are some guideposts to help contributors get started with the code and ensure that their additions fit into the structure and style of the Gem. If you are new to the project, we hope this will help you along the way, if you find something is missing, however, please open an issue in GitHub against the documentation; or, since the documentation itself is part of the open source project, please feel free to submit changes to this guide which might leave some footprints those who follow along behind you.

# Contributer License Agreement

Contributions to the softlayer-ruby project require the submission of a
contributer license agreement. Individual contributers should review and
complete the [CLA](./cla-individual.md). Contributions made of behalf of a 
company/employer will necessitate the completion of the [CCLA](./cla-corporate.md).

# Requesting Changes

Any requests for enhancements, new features, or bug reports should be entered into the softlayer-ruby GitHub repository as "[issues](https://github.com/softlayer/softlayer-ruby/issues?state=open)".

# Development Environment

As a Ruby project, your first step will be to install the [Ruby Programming Language](https://www.ruby-lang.org/en/). Many Unix-derived environments, including Mac OS X, have a version or Ruby installed by default, however, the default version may be out-of-date. Please visit the main Ruby language [site](https://www.ruby-lang.org/en/) for instructions on installing an up-to-date build of Ruby for your computing environment. 

The Gem supports multiple versions of Ruby, and we recommend using Ruby 2.0 or later. The [Ruby Version Manager (rvm)](https://rvm.io) is an invaluable tool to help keep track of multiple versions of Ruby. The Gem no longer supports Ruby 1.8.7.  Support for Ruby 1.9 will continue for a time, but the Core Ruby team is already withdrawing their support for that version.

Source code management is handled through [Git](http://git-scm.com), and GitHub hosts the primary repository, [Softlayer-Ruby](https://github.com/softlayer/softlayer-ruby). GitHub also handles bug tracking and feature suggestions through issues.

The `softlayer_api` gem is a pure Ruby project. There are, at the time of this writing, no native libraries built into the gem so no native C or C++ tools should be necessary. If you prefer to use a Ruby IDE, any of them should work, as should a simple text editor such as [vim](http://www.vim.org), [emacs](http://www.gnu.org/software/emacs/), [Sublime](http://www.sublimetext.com) or [TextMate](http://macromates.com).

Source code documentation is built using [Rdoc](https://github.com/rdoc/rdoc)

Unit testing is handled through [RSpec](http://rspec.info) and we prefer specs to *try* to follow the guidelines found at [betterspecs.org](http://betterspecs.org).

Building and makefile functionality is handled by [Rake](https://github.com/jimweirich/rake).

Configuration and dependency management is accomplished using [Bundler](http://bundler.io)

When changes are submitted to GitHub, the [Travis CI](https://travis-ci.org) continuous integration platform runs the unit tests as a means of smoke testing submitted code.

# Setting up

To set up a development environment you should have Ruby installed and select an editor. Fork the [Softlayer-Ruby](https://github.com/softlayer/softlayer-ruby) project in GitHub, and clone your fork to your local machine. Change into the root directory, and if necessary, use the Ruby Gems command line tools to install bundler:

    $ gem install bundler

To ask Bundler to install all the other gems required to work with the `softlayer_api` gem, issue the command:

    $ bundler install

At this point you should be able to run all the unit tests for the gem.  Running the unit tests is as easy as invoking rake with the default build action:

    $ rake

Once the unit tests are finished you should see a completion message that looks something like:

    Finished in 1.19 seconds (files took 0.50089 seconds to load)
    252 examples, 0 failures

(The actual number of examples run will probably vary)

# Building the Gem

To build the gem, you ask rake to do the heavy lifting:

    $ rake build

gems are built into the `pkg` directory and will have a name of the form `softlayer_api-<version>.gem.` where `<version>` will be the version of the `softlayer_api` gem.

You can install your modified gem to your system with the gem command:

    $ bundle gem install pkg/softlayer_api-<version>.gem

(don't forget to substitute the version you are installing where the `<version>` tag appears in the command line above)

# Running the Tests

The unit tests in the Gem are written using [RSpec](http://rspec.info).  They are also integrated into the `rake` build system and the default action is to run the tests. As a result, from the root source directory, any of the following commands will run the unit tests:

    $ rspec
    $ rake spec
    $ rake

Coverage of the unit tests is not 100%, but we heartily recommend that you add unit tests for any new code you add to the gem.

# Building documentation

To build documentation for the gem, use the `rdoc` or `rerdoc` actions with the `rake` command:

    $ rake rdoc
	$ rake rerdoc

documentation is built in the `doc` folder and the main file is `doc/index.html`

API documentation is written inline within the source using RDoc.  Supplementary documentation is found in the doc_src folder and is primarily written in [markdown](http://daringfireball.net/projects/markdown/syntax).

# Directory Structure

The basic directory structure for the source tree is as follows

    doc           # Built by RDoc when documentation is generated
	doc_src		  # Static pages (in markdown format) that are included with the documentation.  You're reading one now.
	examples      # Sample scripts offering examples of using the softlayer_api gem
	lib           # Container for the source code of the gem
	  softlayer   # Folder containing most of the gem's actual source code
	log			  # RVM will create a log folder when running commands across multiple ruby versions.
	pkg			  # Created when the gem is built, contains built versions of the gem
	spec		  # Source directory for the RSpec testing specifications 
	  fixtures    # Files used by the unit tests to mock responses from the SoftLayer network API

Most of the source files that implement the gem are found in `lib/softlayer`.  If you wish to add new functionality, or edit existing functionality, you will probably edit the class files in this directory. Unit tests using Rspec are found in the spec folder and should generally follow the naming convention of <Class>_spec.rb

Although there are exceptions, most of the source code follows the convention of having a single source file per class, and the file is named after the class it contains.

# Style

Questions of coding style are the source of massive levels of angst and unrest in development communities. We ask contributors to be tolerant in what they will accept, and liberal in their personal style. We ask contributors to review the [ruby style guide](https://github.com/styleguide/ruby) available on GitHub.  In particular we prefer that contributors follow the suggestions:

* Use soft-tabs with a two space indent.
* Keep lines fewer than 80 characters (more or less).
* Never leave trailing whitespace.
* End each file with a blank newline.

Commits to the project to remove whitespace have been made, although we prefer them as stand-alone commits with appropriate commenting.

Contrary to the style guide, we use Rdoc for documentation not TomDoc.

We strongly recommend that the naming guidelines in the style guide be followed. Ruby language variables and methods should be named using `snake_case`. This is particularly valuable since the SoftLayer network API uses `camelCase` as its naming convention and having the two styles helps to indicate which environment a method name or identifier comes from.

The Gem uses an exclamation mark (!) to mark methods that have strong consequences to the SoftLayer Environment.  This includes methods that delete, destroy, or otherwise permanently modify an entity in the environment, or requests that might cause additional charges to be applied to a customer account.  For example, the method for permanently canceling a server is `cancel!` and the method for placing an order (and incurring additional charges to the account) is `place_order!`.

# Model Layer Changes

The Model Layer of the `softlayer_api` gem is intended to allow scripts to access information easily and make common modifications to a SoftLayer environment with straightforward code. As such, it is important that the model itself be sound. For contributors who wish to add new models to this layer, we recommend that you present your design in an issue on GitHub and solicit the constructive advice of the community on your model.  In particular we recommend the following for consideration on good model design:

* [SOLID object oriented design](http://en.m.wikipedia.org/wiki/SOLID_(object-oriented_design))
* [The DRY principle](http://en.wikipedia.org/wiki/Don't_repeat_yourself)

These are guidelines, not rules, and model design is as subject to opinion and subjectivity as other programming topics.

If you intend to offer new models, please carefully review the Model Layer documentation in this set as subclasses of ModelBase are expected to conform to particular protocols.

# Submitting Changes

Contributions are made to the `softlayer_api` Gem by submitting a pull-request on GitHub. The community will review pull requests and offer constructive advice on improvements.  The determination on whether a pull-request will be accepted into the gem is made at the sole discretion of SoftLayer with the wise counsel of the community.

