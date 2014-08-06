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

require 'configparser'

module SoftLayer

  # The SoftLayer Config class is responsible for providing the key information 
  # the library needs to communicate with the network SoftLayer API. Those three crucial
  # pieces of information are the Username, the API Key, and the endpoint_url. This information
  # is collected in a hash with the keys `:username`, `:api_key`, and `:endpoint_url` repsectively.
  # 
  # The routine used to retrieve this information from a Config object is Config.client_settings
  #
  # There are several locations that the Config class looks for this information:
  #
  # * Stored in a configuration file
  # * In the Environment Variables of the running process
  # * Placed in Global Variables
  # * In a hash provided directly to the Config class.
  #
  # These locations are searched in the order listed above.  Information found
  # lower in this list will replace the information found at higher levels.  For example
  # if the configuration file provides a username but a different username is also set
  # in the global variables, the Config class allows the global variable to override the name
  # from the config file.
  #
  # = Config File
  #
  # The library will search for the SoftLayer config file at the file locations listed in
  # the `SoftLayer::Config::FILE_LOCATIONS` array. The config file follows the format
  # recognized by Python's ConfigParser class (and consequently is compatible with the)
  # SoftLayer-Python language bindings).  A simple config file looks something like this:
  #
  #      [softlayer]
  #      username = joeusername
  #      api_key = DEADBEEFBADF00D
  #      timeout = 60
  #
  # = Environment Variables
  #
  # The config class will search the environment variables SL_USERNAME and SL_API_KEY for 
  # the username and API key respectively. The endpoint_url may not be set thorugh
  # environment variables.
  #
  # = Global Variables
  #
  # The names of the global variables that can be used to provide authentication key are:
  #
  # - +$SL_API_USERNAME+
  # - +$SL_API_KEY+
  # - +$SL_API_BASE_URL+
  #
  # = Direct parameters
  #
  # Finally, the Config.client_settings routine accepts a hash of arguments. If any
  # of the key information is provided in that hash, that information will override
  # any discovered through the techniques above.
  #

	class Config
		def Config.globals_settings
			result = {}
			result[:username] =  $SL_API_USERNAME if $SL_API_USERNAME
			result[:api_key] = $SL_API_KEY if $SL_API_KEY
			result[:endpoint_url] = $SL_API_BASE_URL || API_PUBLIC_ENDPOINT
			result
		end

		def Config.environment_settings
			result = {}
			result[:username] =  ENV["SL_USERNAME"] if ENV["SL_USERNAME"]
			result[:api_key] = ENV["SL_API_KEY"] if ENV["SL_API_KEY"]
			result
		end

		FILE_LOCATIONS = ['/etc/softlayer.conf', '~/.softlayer', './.softlayer']

		def Config.file_settings(*additional_files)
			result = {}

			search_path = FILE_LOCATIONS
			search_path = search_path + additional_files if additional_files
			search_path = search_path.map { |file_path| File.expand_path(file_path) }

			search_path.each do |file_path|
				if File.readable? file_path
					config = ConfigParser.new file_path
					softlayer_section = config["softlayer"]

					if softlayer_section
						result[:username] = softlayer_section['username'] if softlayer_section['username']
						result[:endpoint_url] = softlayer_section['endpoint_url'] if softlayer_section['endpoint_url']
						result[:api_key] = softlayer_section['api_key'] if softlayer_section['api_key']
						result[:timeout] = softlayer_section['timeout'] if softlayer_section['timeout']
					end
				end
			end

			result
		end

		def Config.client_settings(provided_settings = {})
      settings = { :endpoint_url => API_PUBLIC_ENDPOINT }
			settings.merge! file_settings
			settings.merge! environment_settings
			settings.merge! globals_settings
			settings.merge! provided_settings

			settings
		end
	end
end
