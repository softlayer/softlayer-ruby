#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  class NetworkComponent < SoftLayer::ModelBase
    ##
    # :attr_reader: max_speed
    # A network component's maximum allowed speed,
    sl_attr :max_speed, 'maxSpeed'

    ##
    # :attr_reader:
    # A network component's maximum allowed speed,
    #
    # DEPRECATION WARNING: This attribute is deprecated in favor of max_speed
    # and will be removed in the next major release.
    sl_attr :maxSpeed

    ##
    # :attr_reader:
    # A network component's short name.
    sl_attr :name

    # :attr_reader:
    # A network component's port number.
    sl_attr :port

    ##
    # :attr_reader: 
    # A network component's speed, measured in Mbit per second.
    sl_attr :speed
  end
end
