require File.expand_path('../lib/producer/rails/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'producer-rails'
  s.version     = Producer::Rails::VERSION.dup
  s.summary     = 'producer rails addon'
  s.description = 'Rails helpers for producer (producer-core gem)'
  s.license     = 'BSD-3-Clause'
  s.homepage    = 'https://rubygems.org/gems/producer-rails'

  s.authors     = 'Thibault Jouan'
  s.email       = 'tj@a13.fr'

  s.files       = `git ls-files lib`.split $/
  s.extra_rdoc_files = %w[README.md]


  s.add_dependency 'producer-core',   '~> 0.5'
  s.add_dependency 'producer-stdlib', '~> 0.1'

  s.add_development_dependency 'aruba',         '~> 0.8', '< 0.9'
  s.add_development_dependency 'cucumber',      '~> 2.0'
  s.add_development_dependency 'cucumber-sshd', '~> 1.1'
  s.add_development_dependency 'pg',            '~> 0.18'
  s.add_development_dependency 'rake',          '~> 10.4'
  s.add_development_dependency 'rails',         '~> 4.2'
end
