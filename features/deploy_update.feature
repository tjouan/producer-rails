@sshd @sshd_gem_env @mocked_home_directory
Feature: `deploy_update' macro

  Background:
    Given a rails app repository
    And I make the initial deployment
    And I make a change in the rails app repository
    And I write a deployment recipe calling "deploy_update"

  Scenario: updates the deployed app repository
    When I execute the deployment recipe
    Then the deployed app repository must be up to date
