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

module SoftLayer
  class BareMetalServerOrder < BareMetalOrder
    #--
    # Required Attributes
    # -------------------
    # Bare Metal Server orders must include the package_id for the server being ordered.
    #
    # Appropriate packages can be found using +BareMetalServerOrder.bare_metal_server_packages+
    #++

    # Fixnum, The package corresponding to the chassis for the server being ordered
    attr_accessor :package_id

    ##
    #
    # Retrieves a list of packages that are available for ordering
    # bare metal servers.
    #
    # Each package identifies it's :package_id, :package_name, and :package_description
    #
    # Note that :package_descriptions contain HTML tags.
    #
    def self.bare_metal_server_packages(client)
      package_service = client['Product_Package']

      filter = SoftLayer::ObjectFilter.build('type.keyName') { is('BARE_METAL_CPU') }
      package_data = package_service.object_filter(filter).object_mask('mask[id, name, description]').getAllObjects

      # Filter out packages without a name or that are designated as 'OUTLET.'
      # The outlet packages are missing some necessary data and orders based on them will fail.
      package_data = package_data.select { |package_datum| package_datum['name'] && !package_datum['description'].include?('OUTLET') }

      package_data.collect do |package_datum|
        {
          :package_id => package_datum['id'],
          :package_name => package_datum['name'],
          :package_description => package_datum['description']
        }
      end
    end #bare_metal_server_packages
  end # BareMetalServerOrder
end # SoftLayer