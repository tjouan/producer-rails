@sshd @sshd_gem_env
Feature: producer recipe arguments usage

  Background:
    Given a rails app repository

  Scenario: `init' recipe argument is given
    Given I write a standard deployment recipe
    When I execute the deployment recipe with "init" recipe argument
    Then the deployed app must be initialized

  Scenario: `update' recipe argument is given
    Given I make the initial deployment
    And I make a change in the rails app repository
    And I write a standard deployment recipe
    When I execute the deployment recipe with "update" recipe argument
    Then the deployed app repository must be up to date

  @unicorn_kill
  Scenario: `start' recipe argument is given
    Given I make the initial deployment
    And I write a standard deployment recipe
    When I execute the deployment recipe with "start" recipe argument
    Then the deployed app unicorn server must be running

  Scenario: `stop' recipe argument is given
    Given I make the initial deployment
    And I start the deployed app
    And I write a standard deployment recipe
    When I execute the deployment recipe with "stop" recipe argument
    Then the deployed app unicorn server must not be running

  @unicorn_kill
  Scenario: `restart' recipe argument is given
    Given I make the initial deployment
    And I start the deployed app
    And the deployed app unicorn server is running with a certain pid
    And I write a standard deployment recipe
    When I execute the deployment recipe with "restart" recipe argument
    Then the deployed app unicorn server must have a different pid

  Scenario: multiple arguments are given
    Given I make the initial deployment
    And I make a change in the rails app repository
    And I start the deployed app
    And the deployed app unicorn server is running with a certain pid
    And I write a standard deployment recipe
    When I execute the deployment recipe with "update restart" recipe arguments
    Then the deployed app repository must be up to date
    Then the deployed app unicorn server must have a different pid
