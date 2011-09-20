# Copyright (c) 2010, SoftLayer Technologies, Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#  * Neither SoftLayer Technologies, Inc. nor the names of its contributors may
#    be used to endorse or promote products derived from this software without
#    specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

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
  VERSION = "1.0.4"  # version history at the bottom of the file.

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