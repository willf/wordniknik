# frozen_string_literal: true

require_relative 'wordniknik/version'
require_relative 'wordniknik/utils'
require_relative 'wordniknik/configuration'
require_relative 'wordniknik/client'

module Wordniknik
  class Error < StandardError; end
end
