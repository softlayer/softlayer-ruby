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
  ##
  # An ObjectFilter is a tool that, when passed to the SoftLayer API
  # allows the API server to filter, or limit the result set for a call.
  #
  # Constructing ObjectFilters is an art that is currently somewhat
  # arcane. This class tries to simplify filtering for the fundamental
  # cases, while still allowing for more complex ObjectFilters to be
  # created.
  #
  # To construct an object filter you begin with an instance of the
  # class. At construction time, or in a "modify" call you can change
  # the filter criteria using a fancy DSL syntax.
  #
  # For example, to filter virtual servers so that you only get ones
  # whose domains end with "layer.com" you might use:
  #
  #    object_filter = ObjectFilter.new do |filter|
  #      filter.accept(virtualGuests.domain).when_it ends_with("layer.com")
  #    end
  #
  # The set of criteria that can be included after "when_it" are defined
  # by routines in the ObjectFilterDefinitionContext module.
  class ObjectFilter
    def initialize(&construction_block)
      @filter_hash = {}
      self.modify(&construction_block)
      self
    end

    def empty?
      @filter_hash.empty?
    end

    def modify(&construction_block)
      ObjectFilterDefinitionContext.module_exec(self, &construction_block) if construction_block
    end

    def accept(key_path)
      CriteriaAcceptor.new(self, key_path)
    end

    def to_h
      return @filter_hash.dup
    end

    def criteria_for_key_path(key_path)
      raise "The key path cannot be empty when searching for criteria" if key_path.nil? || key_path.empty?

      current_level = @filter_hash
      keys = key_path.split('.')

      while current_level && keys.count > 1
        current_level = current_level[keys.shift]
      end

      if current_level
        current_level[keys[0]]
      else
        nil
      end
    end

    def set_criteria_for_key_path(key_path, criteria)
      current_level = @filter_hash
      keys = key_path.split('.')

      current_key = keys.shift
      while current_level && !keys.empty?
        if !current_level.has_key? current_key
          current_level[current_key] = {}
        end
        current_level = current_level[current_key]
        current_key = keys.shift
      end

      current_level[current_key] = criteria
    end

    class CriteriaAcceptor
      def initialize(filter, key_path)
        @filter = filter
        @key_path = key_path
      end

      def when_it(criteria)
        @filter.set_criteria_for_key_path(@key_path, criteria)
      end
    end
  end # ObjectFilter

  OBJECT_FILTER_OPERATORS = [
    '*=',   # Contains (ignoring case)
    '^=',   # Begins with (ignoring case)
    '$=',   # Ends with (ignoring_case)
    '_=',   # Matches (ignoring case)
    '!=',   # Is not Equal To (case sensitive)
    '<=',   # Less than or Equal To (case sensitive)
    '>=',   # Greater than or Equal To (case sensitive)
    '<',    # Less Than (case sensitive)
    '>',    # Greater Than (case sensitive)
    '~',    # Contains (case sensitive)
    '!~'    # Does not Contain (case sensitive)
  ]

  ##
  # The ObjectFilterDefinitionContext defines a bunch of methods
  # that allow the property conditions of an object filter to
  # be defined in a "pretty" way. Each method returns a block
  # (a lambda, a proc) that, when called and pased the tail property
  # of a property chain will generate a fragment of an object filter
  # asking that that property match the given conditions.
  #
  # This class, as a whole, is largely an implementation detail
  # of object filter definitions and there is probably not
  # a good reason to call into it directly.
  module ObjectFilterDefinitionContext
    # Matches when the value in the field is exactly equal to the
    # given value. This is a case-sensitive match
    def self.is(value)
      { 'operation' => value }
    end

    # Matches is the value in the field does not exactly equal
    # the value passed in.
    def self.is_not(value)
      filter_criteria('!=', value)
    end

    # Matches when the value is found within the field
    # the search is not case sensitive
    def self.contains(value)
      filter_criteria('*=', value)
    end

    # Matches when the value is found at the beginning of the
    # field. This search is not case sensitive
    def self.begins_with(value)
      filter_criteria('^=', value)
    end

    # Matches when the value is found at the end of the
    # field. This search is not case sensitive
    def self.ends_with(value)
      filter_criteria('$=', value)
    end

    # Maches the given value in a case-insensitive way
    def self.matches_ignoring_case(value)
      filter_criteria('_=', value)
    end

    # Matches when the value in the field is greater than the given value
    def self.is_greater_than(value)
      filter_criteria('>', value)
    end

    # Matches when the value in the field is less than the given value
    def self.is_less_than(value)
      filter_criteria('<', value)
    end

    # Matches when the value in the field is greater than or equal to the given value
    def self.is_greater_or_equal_to(value)
      filter_criteria('>=', value)
    end

    # Matches when the value in the field is less than or equal to the given value
    def self.is_less_or_equal_to(value)
      filter_criteria('<=', value)
    end

    # Matches when the value is found within the field
    # the search _is_ case sensitive
    def self.contains_exactly(value)
      filter_criteria('~', value)
    end

    # Matches when the value is not found within the field
    # the search _is_ case sensitive
    def self.does_not_contain(value)
      filter_criteria('!~', value)
    end

    # Matches when the property's value is null
    def self.is_null
      { 'operation' => 'is null' }
    end

    # Matches when the property's value is not null
    def self.is_not_null()
      { 'operation' => 'not null' }
    end

    # This is a catch-all criteria matcher that allows for raw object filter conditions
    # not covered by the more convenient methods above. The name is intentionally, annoyingly
    # long and you should use this routine with solid knowledge and great care.
    def self.satisfies_the_raw_condition(condition_hash)
      condition_hash
    end

    # Accepts a query string defined by a simple query language.
    # It translates strings in that language into criteria blocks
    #
    # Object Filter comparisons can be done using operators.  The
    # set of accepted operators is found in the OBJECT_FILTER_OPERATORS
    # array.  The query string can consist of an operator followed
    # by a space, followed by operand
    # e.g.
    #     "*= smaug"
    #
    # The query language also accepts some aliases using asterisks
    # in a regular-expression-like way. Those aliases look like:
    #
    #   'value'   Exact value match (translates to '_= value')
    #   'value*'  Begins with value (translates to '^= value')
    #   '*value'  Ends with value (translates to '$= value')
    #   '*value*' Contains value (translates to '*= value')
    #
    # This method corresponds to the +query_filter+ method in the SoftLayer-Python
    # API.
    def self.matches_query(query_string)
      query = query_string.to_s.strip

      operator = OBJECT_FILTER_OPERATORS.find do | operator_string |
        query[0 ... operator_string.length] == operator_string
      end

      if operator then
        filter_criteria(operator, query[operator.length..-1])
      else
        case query
        when /\A\*(.*)\*\Z/
          contains($1)
        when /\A\*(.*)/
          ends_with($1)
        when /\A(.*)\*\Z/
          begins_with($1)
        else
          matches_ignoring_case(query)
        end #case
      end #if
    end

    private

    def self.cleaned_up_operand(operand)
      # try to convert the operand to an integer.  If it works, return
      # that integer
      begin
        return Integer(operand)
      rescue
      end

      # The operand could not be converted to an integer so we try to make it a string
      # and clean up the string
      filter_operand = operand.to_s.strip
    end

    def self.filter_criteria(with_operator, operand)
      filter_operand = cleaned_up_operand(operand)
      filter_condition = "#{with_operator.to_s.strip} #{operand.to_s.strip}"
      { 'operation' => filter_condition }
    end
  end
end # SoftLayer
