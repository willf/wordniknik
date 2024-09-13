# frozen_string_literal: true

# deep transform keys of a hash to symbols in snake case
require 'time'

module Wordniknik
  module_function

  def to_timestamp_safely(thing)
    if thing.is_a?(String)
      if thing.match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(:?\.\d{2,4})?Z$/)
        return Time.parse(thing)
      elsif thing.match(/^\d{4}-\d{2}-\d{2}$/)
        return Date.parse(thing)
      end

      return thing
    end
    thing
  end

  def capitalize_simple(str)
    return str if str.empty?

    str[0].upcase + str[1..]
  end

  def lowercase_simple(str)
    return str if str.empty?

    str[0].downcase + str[1..]
  end

  def to_underscore(str)
    str = str.to_s
    str.gsub('::', '/')
       .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
       .gsub(/([a-z\d])([A-Z])/, '\1_\2')
       .tr('-', '_')
       .downcase
  end

  def to_camel(str)
    str = str.to_s
    return str if str.empty?

    s = str.split('_').map { |part| capitalize_simple(part) }.join
    lowercase_simple(s)
  end

  def to_snake_case(thing)
    if thing.is_a?(Array)
      return thing.map { |v| to_snake_case(v) }
    elsif thing.is_a?(String)
      return to_timestamp_safely(thing)
    elsif !thing.is_a?(Hash)
      return thing
    end

    # else it's a hash
    result = {}
    thing.each do |key, value|
      if value.is_a?(Hash)
        value = to_snake_case(value)
      elsif value.is_a?(Array)
        value = value.map { |v| to_snake_case(v) }
      end
      value = to_timestamp_safely(value)
      result[to_underscore(key).to_sym] = value
    end
    result
  end

  def to_camel_case(thing)
    if thing.is_a?(Array)
      return thing.map { |v| to_camel_case(v) }
    elsif !thing.is_a?(Hash)
      return thing
    end

    # else it's a hash
    result = {}
    thing.each do |key, value|
      if value.is_a?(Hash)
        value = to_camel_case(value)
      elsif value.is_a?(Array)
        value = value.map { |v| to_camel_case(v) }
      end
      result[to_camel(key).to_sym] = value
    end
    result
  end
end
