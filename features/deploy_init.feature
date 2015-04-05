@sshd @sshd_gem_env @mocked_home_directory
Feature: `deploy_init' macro

  Background:
    Given a rails app repository in remote directory "repos/my_app"
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
