@sshd @sshd_gem_env @mocked_home_directory
Feature: `deploy_start' macro

  Background:
    Given a rails app repository
    And I make the initial deployment
    And I write a deployment recipe calling "deploy_start"

  @unicorn_kill
  Scenario: starts unicorn server
    When I execute the deployment recipe
    Then the deployed app unicorn server must be running
