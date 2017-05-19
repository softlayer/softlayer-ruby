#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

require 'rubygems'

##
# The SoftLayer module provides a namespace for SoftLayer code.
#
module SoftLayer
  # The version number (including major, minor, and bugfix numbers)
  # This should change in accordance with the concept of Semantic Versioning
  VERSION = "3.2.2"  # version history in the CHANGELOG.textile file at the root of the source

  # The base URL of the SoftLayer API available to the public internet.
  API_PUBLIC_ENDPOINT = 'https://api.softlayer.com/xmlrpc/v3/'

  # The base URL of the SoftLayer API available through SoftLayer's private network
  API_PRIVATE_ENDPOINT = 'https://api.service.softlayer.com/xmlrpc/v3/'

  #--
  # These globals can be used to simplify client creation
  #++

  # Set this if you want to provide a default username for each client as it is created.
  # usernames provided to the client initializer will override the global
  $SL_API_USERNAME = nil

  # Set this if you want to provide a default api_key for each client as it is
  # created. API keys provided in the constructor when a client is created will
  # override the values in this global
  $SL_API_KEY = nil

  # The base URL used for the SoftLayer API's
  $SL_API_BASE_URL = SoftLayer::API_PUBLIC_ENDPOINT
end # module SoftLayer

#
# History:
#
# The history can be found in the CHANGELOG.textile file in the project root directory
