# frozen_string_literal: true

require 'yaml'

module Wordniknik
  WORDNIK_CONFIG_FILE = '.wordnik.yml'
  class Configuration
    attr_accessor :api_key, :api_host, :api_port, :api_version, :connection

    def initialize
      defaults = {
        api_host: 'api.wordnik.com',
        api_port: 443,
        api_version: 'v4'
      }
      loaded = look_for_config_file
      @api_key = loaded['api_key'] || ENV.fetch('WORDNIK_API_KEY', nil)
      @api_host = loaded['api_host'] || defaults[:api_host]
      @api_port = loaded['api_port'] || defaults[:api_port]
      @api_version = loaded['api_version'] || defaults[:api_version]
      return unless @api_key.nil?

      raise "No API key found. Please set it in the environment variable WORDNIK_API_KEY or in a #{WORDNIK_CONFIG_FILE} file."
    end

    def look_for_config_file
      if File.exist?(WORDNIK_CONFIG_FILE)
        YAML.load_file(WORDNIK_CONFIG_FILE)
      elsif File.exist?(File.join(Dir.home, WORDNIK_CONFIG_FILE))
        YAML.load_file(File.join(Dir.home, WORDNIK_CONFIG_FILE))
      else
        {}
      end
    end

    def to_s
      "<Configuration api_key: *****, api_host: #{@api_host}:#{@api_port}, api_version: #{@api_version}>"
    end

    def inspect
      to_s
    end
  end
end
