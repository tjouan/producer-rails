@sshd @sshd_gem_env @mocked_home_directory
Feature: `deploy_stop' macro

  Background:
    Given a rails app repository
    And I make the initial deployment
    And I start the deployed app
    And I write a deployment recipe calling "deploy_stop"

  Scenario: stops unicorn server
    When I execute the deployment recipe
    Then the deployed app unicorn server must not be running
