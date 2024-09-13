# frozen_string_literal: true

require_relative "lib/wordniknik/version"

Gem::Specification.new do |spec|
  spec.name = "wordniknik"
  spec.version = Wordniknik::VERSION
  spec.authors = ["Will Fitzgerald"]
  spec.email = ["willf@userspec.noreply.github.com"]

  spec.summary = 'A ruby wrapper for the Wordnik API'
  spec.description = 'This gem provides a simple interface to the Wordnik API.'
  spec.homepage = 'https://github.com/willf/wordniknik'
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = #{spec.homepage}/blob/main/CHANGELOG.md

  spec.files         = Dir.glob('lib/**/*')
  spec.require_paths = ['lib']
  spec.test_files    = Dir.glob('spec/**/*')

  spec.add_dependency 'json'

  spec.add_development_dependency 'faraday'
  spec.add_development_dependency 'gem-release'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rake'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'vcr'
  spec.add_development_dependency 'yard'

end
