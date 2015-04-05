@sshd @sshd_gem_env
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

  Scenario: creates remote app dir
    When I successfully execute the recipe on remote target
    Then the remote directory "deploys/my_app" must exist
