producer-rails
==============

[![Version      ][badge-version-img]][badge-version-uri]


  Ruby on Rails specific macros and tests for [producer][].


Usage
-----

```ruby
# config/deploy.rb
require 'producer/rails'

set :repository,  'git.example:repository_path'
set :app_path,    'deployment_path'

deploy
```

```
# Deploy for the first time
$ producer config/deploy.rb -t host.example -- init

# Deploy updated application (with application restart)
$ producer config/deploy.rb -t host.example -- update

# Start application
$ producer config/deploy.rb -t host.example -- start

# Stop application
$ producer config/deploy.rb -t host.example -- stop

# Restart application
$ producer config/deploy.rb -t host.example -- restart
```



[producer]:           https://github.com/tjouan/producer-core
[badge-version-img]:  https://img.shields.io/gem/v/producer-rails.svg?style=flat-square
[badge-version-uri]:  https://rubygems.org/gems/producer-rails
