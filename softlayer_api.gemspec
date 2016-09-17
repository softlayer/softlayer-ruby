#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__)))
require 'lib/softlayer/base'

Gem::Specification.new do |s|
  s.name = %q{softlayer_api}
  s.version = SoftLayer::VERSION
  s.author = "SoftLayer Development Team"
  s.email = %q{sldn@softlayer.com}
  s.description = %q{The softlayer_api gem offers a convenient mechanism for invoking the services of the SoftLayer API from Ruby.}
  s.summary = %q{Library for accessing the SoftLayer API}
  s.homepage = %q{http://sldn.softlayer.com/}
  s.license = %q{MIT}

  s.files = Dir["README.textile", "LICENSE.textile", "CHANGELOG.textile", "lib/**/*.rb", "test/**/*.rb", "examples/**/*.rb"]
  s.require_paths = ["lib"]

  s.has_rdoc = true
  s.required_ruby_version = '>= 1.9.2'
  s.add_runtime_dependency 'configparser', '~>0.1.2'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rdoc', '>=2.4.2'
  s.add_development_dependency 'json', '~> 1.8', '>= 1.8.1'
  # Fixing the following gems' versions to avoid requiring
  # Ruby 2.0.
  s.add_development_dependency 'mime-types', '= 2.99.3'
  s.add_development_dependency 'coveralls', '= 0.7.2'
end
