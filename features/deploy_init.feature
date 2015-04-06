@sshd @sshd_gem_env @mocked_home_directory
Feature: `deploy_init' macro

  Background:
    Given a rails app repository
    And a recipe with:
      """
      require 'producer/rails'

      set :repository,  'repos/my_app'
      set :app_path,    'deploys/my_app'
      set :www_workers, 2

      deploy_init

      """

  Scenario: clones the app in configured remote directory
    When I successfully execute the recipe on remote target
    Then the remote file "deploys/my_app/config.ru" must exist

  Scenario: configures the database connection
    When I successfully execute the recipe on remote target
    Then the remote file "deploys/my_app/config/database.yml" must contain exactly:
      """
      default: &default
        adapter: postgresql
        encoding: unicode
        pool: 5

      production:
        <<: *default
        database: some_host_test

      """

  Scenario: installs dependencies with bundler
    When I successfully execute the recipe on remote target
    Then the remote file "deploys/my_app/Gemfile.lock" must exist

  Scenario: executes database migrations
    Given database does not exist
    When I successfully execute the recipe on remote target
    Then database migrations for "deploys/my_app" must be up

  Scenario: generates a secret key for production
    When I successfully execute the recipe on remote target
    Then secret key for "deploys/my_app" must be set

  Scenario: configures unicorn server
    When I successfully execute the recipe on remote target
    Then the remote file "deploys/my_app/config/unicorn.rb" must contain exactly:
      """
      worker_processes  2
      timeout           60
      preload_app       false
      pid               'tmp/run/www.pid'
      listen            "#{ENV['HOME']}/deploys/my_app/tmp/run/www.sock"

      """
