#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

module SoftLayer
	class VLANFirewallRuleset < SoftLayer::ModelBase  
    
    # The initial set of rules is taken from the network API,
    # but then the user is free to manipulate the rules and 
    # ask the system to update the firewall.  As a result
    # the rules property can get out-of-sync with the actual rules
    # on the network. To re-fetch the set of rules from the network
    # use the #refresh_rules method.
    attr_accessor :rules

    def initialize(softlayer_client, network_hash)
      super(softlayer_client, network_hash)
      self.refresh_rules
    end

    def service
      return self.softlayer_client[:Network_Firewall_AccessControlList].object_with_id(self.id)
    end

    def softlayer_properties(object_mask = nil)
      self.service.object_mask(self.class.default_object_mask).getObject
    end

    def self.default_rules_mask
      return "mask[orderValue,action,destinationIpAddress,destinationIpSubnetMask,protocol,destinationPortRangeStart,destinationPortRangeEnd,sourceIpAddress,sourceIpSubnetMask,version]"
    end

    def refresh_rules
      self.rules = self.softlayer_client[:Network_Firewall_AccessControlList].object_with_id(self.id).object_mask(self.class.default_rules_mask).getRules
    end
  end
end

