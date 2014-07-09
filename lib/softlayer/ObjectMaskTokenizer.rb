#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

require 'softlayer/ObjectMaskToken'
require 'strscan'

module SoftLayer
  #
  # This class is an implementation detail of the ObjectMaskParser
  #
  # It takes an Object Mask String and breaks it down
  # into ObjectMaskToken instances.
  #
  class ObjectMaskTokenizer
    ObjectMask_Token_Specs = [
      [/\[/, :property_set_start],
      [/\,/, :property_set_separator],
      [/\]/, :property_set_end],
      [/\(/, :property_type_start],
      [/\)/, :property_type_end],
      [/\./, :property_child_separator],
      [/[a-z][a-z0-9_]*/i, :identifier]
    ]

    def initialize(mask_string)
      @mask_string = mask_string.clone
      @scanner = StringScanner.new(@mask_string)
      @current_token = nil
    end

    def more_tokens?
      return @current_token == nil || !@current_token.end_of_string?
    end

    def current_token
      @current_token = next_token if !@current_token
      @current_token
    end

    def next_token
      # if we're at the end of the string, we keep returning the
      # EOS token
      if more_tokens? then

        if !@scanner.eos?
          # skip whitespace
          @scanner.skip(/\s+/)

          # search through the token specs to find which (if any) matches
          token_spec = ObjectMask_Token_Specs.find() do |token_spec|
            @scanner.check(token_spec[0])
          end

          # if a good token spec was found, set the current token to the one found
          if token_spec
            @current_token = ObjectMaskToken.new(token_spec.last, @scanner.scan(token_spec[0]))
          else
            @current_token = ObjectMaskToken.new(:invalid_token, @scanner.rest)
            @scanner.terminate
          end
        else
          @current_token = ObjectMaskToken.new(:eos)
        end
      end

      @current_token
    end
  end
end # module SoftLayer