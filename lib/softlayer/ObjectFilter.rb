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

  # A class whose instances represent an Object Filter operation.
  class ObjectFilterOperation
    attr_reader :operator
    attr_reader :value

    def initialize(operator, value)
      raise ArgumentException, "An unknown operator was given" if !OBJECT_FILTER_OPERATORS.include?(operator.strip)
      raise ArgumentException, "Expected a value" if value.nil? || (value.respond_to?(:empty?) && value.empty?)

      @operator = operator.strip
      @value = value.strip
    end

    def to_h
      { 'operation' => "#{operator} #{value}"}
    end
  end

  # This class defines the routines that are valid within the block provided to a call to
  # ObjectFilter.build. This allows you to create object filters like:
  #
  # object_filter = SoftLayer::ObjectFilter.build("hardware.memory") { is_greater_than(2) }
  #
  class ObjectFilterBlockHandler
    # Matches when the value is found within the field
    # the search is not case sensitive
    def contains(value)
      ObjectFilterOperation.new('*=', value)
    end

    # Matches when the value is found at the beginning of the
    # field.  This search is not case sensitive
    def begins_with(value)
      ObjectFilterOperation.new('^=', value)
    end

    # Matches when the value is found at the end of the
    # field.  This search is not case sensitive
    def ends_with(value)
      ObjectFilterOperation.new('$=', value)
    end

    # Matches when the value in the field is exactly equal to the
    # given value.  This is a case-sensitive match
    def is(value)
      ObjectFilterOperation.new('_=', value)
    end

    # Matches is the value in the field does not exactly equal
    # the value passed in.
    def is_not(value)
      ObjectFilterOperation.new('!=', value)
    end

    # Matches when the value in the field is greater than the given value
    def is_greater_than(value)
      ObjectFilterOperation.new('>', value)
    end

    # Matches when the value in the field is less than the given value
    def is_less_than(value)
      ObjectFilterOperation.new('<', value)
    end

    def is_greater_or_equal_to(value)
      ObjectFilterOperation.new('>=', value)
    end

    def is_less_or_equal_to(value)
      ObjectFilterOperation.new('<=', value)
    end

    # Matches when the value is found within the field
    # the search _is_ case sensitive
    def contains_exactly(value)
      ObjectFilterOperation.new('~', value)
    end

    # Matches when the value is not found within the field
    # the search _is_ case sensitive
    def does_not_contain(value)
      ObjectFilterOperation.new('!~', value)
    end
  end

  # An ObjectFilter is a hash that, when asked to provide
  # an value for an unknown key, will create a sub element
  # at that key which is, itself, an object filter.
  # This allows you to build up object filters by chaining [] defeference
  # operations.
  #
  # Starting empty object filter when you ask for <tt>object_filter["foo"]</tt>
  # either the value at that hash location will be returned, or foo will be +added+ to the
  # object and the value of that key will be an Object Filter <tt>{ "foo" => {} }</tt>
  #
  # By way of an example of chaining together +[]+ calls:
  #   object_filter["foo"]["bar"]["baz"] = 3
  # yields an object filter like this:
  #   {"foo" => { "bar" => {"baz" => 3}}}
  #
  class ObjectFilter < Hash
    # The default initialize for a hash is overridden
    # so that object filters create sub-filters when asked
    # for missing keys.
    def initialize
      super do |hash, key|
        hash[key] = ObjectFilter.new
      end
    end

    # Builds an object filter with the given key path, a dot separated list of property keys.
    # The filter itself can be provided as a query string (in the query parameter)
    # or by providing a block that calls routines in the ObjectFilterBlockHandler class.
    def self.build(key_path, query = nil, &block)
      raise ArgumentError, "The key path to build cannot be empty" if !key_path

      # Split the keypath into its constituent parts and notify the user
      # if there are no parts
      keys = key_path.split('.')
      raise ArgumentError, "The key path to build cannot be empty" if keys.empty?

      # This will be the result of the build
      result = ObjectFilter.new

      # chase down the key path to the last-but-one key
      current_level = result
      while keys.count > 1
        current_level = current_level[keys.shift]
      end

      # if there is a block, then the query will come from
      # calling the block.  We warn in debug mode if you override a
      # query that was passed directly with the value from a block.
      if block
        $stderr.puts "The query from the block passed to ObjectFilter:build will override the query passed as a parameter" if $DEBUG && query
        block_handler = ObjectFilterBlockHandler.new
        query = block_handler.instance_eval(&block)
      end

      # If we have a query, we assign its value to the last key
      # otherwise, we build an emtpy filter at the bottom
      if query
        case
        when query.kind_of?(Numeric)
          current_level[keys.shift] = { 'operation' => query }
        when query.kind_of?(SoftLayer::ObjectFilterOperation)
          current_level[keys.shift] = query.to_h
        when query.kind_of?(String)
          current_level[keys.shift] = query_to_filter_operation(query)
        when query.kind_of?(Hash)
          current_level[keys.shift] = query
        else
          current_level[keys.shift]
        end
      else
        current_level[keys.shift]
      end

      result
    end

    # This method tries to simplify creating a correct object filter structure
    # by allowing the caller to provide a string in a simple query language.
    # It then translates that string into an Object Filter operation structure
    #
    # Object Filter comparisons are done using operators. Some operators make
    # case sensitive comparisons and some do not. The general form of an Object
    # Filter operation is an operator follwed by the value used in the comparison.
    # e.g.
    #     "*= smaug"
    #
    # The query language also accepts some aliases using asterisks
    # in a regular-expression-like way.  Those aliases look like:
    #
    #   'value'   Exact value match (translates to '_= value')
    #   'value*'  Begins with value (translates to '^= value')
    #   '*value'  Ends with value (translates to '$= value')
    #   '*value*' Contains value (translates to '*= value')
    #
    def self.query_to_filter_operation(query)
      if query.kind_of? String then
        query.strip!

        begin
          return { 'operation' => Integer(query) }
        rescue
        end

        operator = OBJECT_FILTER_OPERATORS.find do | operator_string |
          query[0 ... operator_string.length] == operator_string
        end

        if operator then
          operation = "#{operator} #{query[operator.length..-1].strip}"
        else
          case query
          when /\A\*(.*)\*\Z/
            operation = "*= #{$1}"
          when /\A\*(.*)/
            operation = "$= #{$1}"
          when /\A(.*)\*\Z/
            operation = "^= #{$1}"
          else
            operation = "_= #{query}"
          end #case
        end #if
      else
        operation = query.to_i
      end # query is string

      { 'operation' => operation }
    end # query_to_filter_operation

  end # ObjectFilter
end # SoftLayer
