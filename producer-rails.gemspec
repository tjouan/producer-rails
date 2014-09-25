require File.expand_path('../lib/producer/rails/version', __FILE__)

Gem::Specification.new do |s|
  s.name    = 'producer-rails'
  s.version = Producer::Rails::VERSION.dup
  s.summary = 'producer rails addon'
  s.description = <<-eoh.gsub(/^ +/, '')
    Rails specific macros for producer (gem: producer-core).
  eoh
  s.homepage = 'https://rubygems.org/gems/producer-rails'

  s.authors = 'Thibault Jouan'
  s.email   = 'tj@a13.fr'

  s.files = `git ls-files`.split $/

  s.add_dependency 'producer-core',   '~> 0.3', '>= 0.3.5'
  s.add_dependency 'producer-stdlib', '~> 0.0', '>= 0.0.5'
end
