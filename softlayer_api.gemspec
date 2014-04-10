#
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__)))
require 'lib/softlayer/base'

Gem::Specification.new do |s|
  s.name = %q{softlayer_api}
  s.version = SoftLayer::VERSION
  s.author = "SoftLayer Development Team"
  s.email = %q{sldn@softlayer.com}
  s.description = %q{The softlayer_api gem offers a convenient mechanism for invoking the services of the SoftLayer API from Ruby.}
  s.summary = %q{Library for accessing the SoftLayer portal API}
  s.homepage = %q{http://sldn.softlayer.com/}
  s.license = %q{MIT}

  s.files = Dir["README.textile", "LICENSE.textile", "lib/**/*.rb", "test/**/*.rb", "examples/**/*.rb"]
  s.require_paths = ["lib"]

  s.has_rdoc = true
  s.add_runtime_dependency 'json', '~> 1.8', '>= 1.8.1'
  s.add_development_dependency 'rake'
end