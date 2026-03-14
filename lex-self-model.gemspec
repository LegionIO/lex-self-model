# frozen_string_literal: true

require_relative 'lib/legion/extensions/self_model/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-self-model'
  spec.version       = Legion::Extensions::SelfModel::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'Metacognitive self-model for LegionIO'
  spec.description   = 'Predictive self-model for LegionIO — ' \
                       'capability tracking, knowledge domain modeling, calibration, and metacognitive introspection'
  spec.homepage      = 'https://github.com/LegionIO/lex-self-model'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']      = spec.homepage
  spec.metadata['source_code_uri']   = spec.homepage
  spec.metadata['documentation_uri'] = "#{spec.homepage}/blob/master/README.md"
  spec.metadata['changelog_uri']     = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']   = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']
end
