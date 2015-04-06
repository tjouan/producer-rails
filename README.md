producer-rails
==============

  Ruby on Rails specific macros and tests for [producer][].

[![Version      ][badge-version-img]][badge-version-uri]
[![Build status ][badge-build-img]][badge-build-uri]


Usage
-----

```ruby
require 'producer/rails'

set :repository,  'git.example:repository_path'
set :app_path,    'deployment_path'

deploy
```



[producer]:           https://github.com/tjouan/producer-core
[badge-version-img]:  https://img.shields.io/gem/v/producer-rails.svg?style=flat-square
[badge-version-uri]:  https://rubygems.org/gems/producer-rails
[badge-build-img]:    https://img.shields.io/travis/tjouan/producer-rails/master.svg?style=flat-square
[badge-build-uri]:    https://travis-ci.org/tjouan/producer-rails
