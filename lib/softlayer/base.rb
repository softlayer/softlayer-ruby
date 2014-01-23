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

# The SoftLayer Module
#
# This module is used to provide a namespace for SoftLayer code.  It also declares a number of
# global variables:
# - <tt>$SL_API_USERNAME</tt> - The default username passed by clients to the server for authentication.
#   Set this if you want to use the same username for all clients and don't want to have to specify it when the client is created
# - <tt>$SL_API_KEY</tt> - The default API key passed by clients to the server for authentication.
#   Set this if you want to use the same api for all clients and don't want to have to specify it when the client is created
# - <tt>$SL_API_BASE_URL</tt>- The default URL used to access the SoftLayer API. This defaults to the value of SoftLayer::API_PUBLIC_ENDPOINT
#

module SoftLayer
  VERSION = "1.0.7"  # version history at the bottom of the file.

  # The base URL of the SoftLayer API's REST-like endpoints available to the public internet.
  API_PUBLIC_ENDPOINT = 'https://api.softlayer.com/rest/v3/'

  # The base URL of the SoftLayer API's REST-like endpoints available through SoftLayer's private network
  API_PRIVATE_ENDPOINT = 'https://api.service.softlayer.com/rest/v3/'

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
# 1.0 - 1.0.1 - Initial release.  There was some confusion over getting the gem
# posted up to rubygems.org and the 1.0.1 release came about because of that
# confusion.  There should be no real functionality differences there.
#
# 1.0.2 - We have some API routines that start with 'get' but expect arguments
# anyway.  The code now uses HTTP POST to send requests for which the user
# has provided arguments regardless of the name of the routine.
#
# 1.0.3 - Added a request filter to add result limits to request.  Submitted by
# JN.  Thanks!
#
# 1.0.4 - Fixed a bug where the result_limit and result_offset object filters were just not working.
#
# 1.0.5 - Fixed a bug where empty hashes and empty arrays would not generate meaningful object masks
#
# 1.0.6 - Make all API calls with either a GET or a POST as the HTTP verb.
#
# 1.0.7 - Calls to the "getObject" method of any service should not take parameters.  The gem now
# warns if you make this type of call and ignores the parameters. This prevents
# SoftLayer_Virtual_Guest::getObject from accidentally creating (billable) CCI instances.