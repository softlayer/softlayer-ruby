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

require 'rubygems'

# This module is used to provide a namespace for SoftLayer code.  It also declares a number of
# global variables:
# - <tt>$SL_API_USERNAME</tt> - The default username passed by clients to the server for authentication.
#   Set this if you want to use the same username for all clients and don't want to have to specify it when the client is created
# - <tt>$SL_API_KEY</tt> - The default API key passed by clients to the server for authentication.
#   Set this if you want to use the same api for all clients and don't want to have to specify it when the client is created
# - <tt>$SL_API_BASE_URL</tt>- The default URL used to access the SoftLayer API. This defaults to the value of <tt>SoftLayer::API_PUBLIC_ENDPOINT</tt>
#
module SoftLayer
  VERSION = "2.0.0"  # version history in the CHANGELOG.textile file at the root of the source

  # The base URL of the SoftLayer API's REST-like endpoints available to the public internet.
  API_PUBLIC_ENDPOINT = 'https://api.softlayer.com/xmlrpc/v3/'

  # The base URL of the SoftLayer API's REST-like endpoints available through SoftLayer's private network
  API_PRIVATE_ENDPOINT = 'https://api.service.softlayer.com/xmlrpc/v3/'

  #
  # These globals can be used to simplify client creation
  #

  # Set this if you want to provide a default username for each service as it is created.
  # usernames provided to the service initializer will override the global
  $SL_API_USERNAME = nil

  # Set this if you want to provide a default api_key for each service as it is
  # created. API keys provided in the constructor when a service is created will
  # override the values in this global
  $SL_API_KEY = nil

  # The base URL used for the SoftLayer API's
  $SL_API_BASE_URL = SoftLayer::API_PUBLIC_ENDPOINT
end # module SoftLayer

#
# History:
#
# The history has been moved to the CHANGELOG.textile file in the source directory
