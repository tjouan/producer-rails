@sshd @sshd_gem_env
Feature: `deploy_restart' macro

  Background:
    Given a rails app repository
    And I make the initial deployment
    And I start the deployed app
    And the deployed app unicorn server is running with a certain pid
    And I write a deployment recipe calling "deploy_restart"

  @unicorn_kill
  Scenario: stops unicorn server
    When I execute the deployment recipe
    Then the deployed app unicorn server must have a different pid
