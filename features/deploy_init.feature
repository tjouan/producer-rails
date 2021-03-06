@sshd @sshd_gem_env
Feature: `deploy_init' macro

  Background:
    Given a rails app repository
    And I write a deployment recipe calling "deploy_init"

  Scenario: clones the app in configured remote directory
    When I execute the deployment recipe
    Then the deployed app repository must be cloned

  Scenario: configures the database connection
    When I execute the deployment recipe
    Then the deployed app must have its database connection configured

  Scenario: installs dependencies with bundler
    When I execute the deployment recipe
    Then the deployed app must have its dependencies installed

  Scenario: executes database migrations
    When I execute the deployment recipe
    Then the deployed app must have its database migrations up

  Scenario: generates a secret key for production
    When I execute the deployment recipe
    Then the deployed app must have secret key setup

  Scenario: configures unicorn server
    When I execute the deployment recipe
    Then the deployed app must have unicorn configuration

  Scenario: adds read permission for group and other on public files
    When I execute the deployment recipe
    Then the deployed app public files must have read permission
