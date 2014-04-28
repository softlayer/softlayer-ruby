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

		FILE_LOCATIONS = ['/etc/softlayer.conf', '~/.softlayer']

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
					end
				end
			end

			result
		end

		def Config.client_settings(provided_settings = {})
			settings = file_settings
			settings.merge! environment_settings
			settings.merge! globals_settings
			settings.merge! provided_settings

			settings
		end
	end
end
