#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
  class NetworkComponent < SoftLayer::ModelBase
    sl_attr :name
    sl_attr :port
    sl_attr :speed
    sl_attr :maxSpeed
  end
end
