Feature: Expected failures

  @expected_failure
  Scenario: Fail
    When I do nothing
    When I raise an exception
    When I do nothing
