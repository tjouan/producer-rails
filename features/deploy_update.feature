@sshd @sshd_gem_env @mocked_home_directory
Feature: `deploy_update' macro

  Background:
    Given a rails app repository
    And I make the initial deployment
    And I make a change in the rails app repository
    And a recipe with:
      """
      require 'producer/rails'

      set :repository,  'repos/my_app'
      set :app_path,    'deploys/my_app'
      set :www_workers, 2

      deploy_update

      """

  Scenario: updates the deployed app repository
    When I successfully execute the recipe on remote target
    Then the deployed app repository must be up to date
