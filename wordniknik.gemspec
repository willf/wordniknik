# frozen_string_literal: true

require_relative 'lib/wordniknik/version'

Gem::Specification.new do |spec|
  spec.name = 'wordniknik'
  spec.version = Wordniknik::VERSION
  spec.authors = ['Will Fitzgerald']
  spec.email = ['willf@userspec.noreply.github.com']

  spec.summary = 'A ruby wrapper for the Wordnik API'
  spec.description = 'This gem provides a simple interface to the Wordnik API.'
  spec.homepage = 'https://github.com/willf/wordniknik'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files         = Dir.glob('lib/**/*')
  spec.require_paths = ['lib']

  spec.add_dependency 'json'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
