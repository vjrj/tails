@product
Feature: Simulate the Tor network with chutney

  Background:
    Given a computer
    And I start Tails from DVD with network unplugged and I login
    And Tails is using a simulated Tor network
    And the network is plugged
    And Tor is ready
    And available upgrades have been checked
    And all notifications have disappeared
    And I save the state so the background can be restored next scenario

  Scenario: We're not using the real Tor network
    When I start the Tor Browser
    And the Tor Browser has started and loaded the startup page
    And I open the address "https://check.torproject.org" in the Tor Browser
    Then I see "UnsafeBrowserTorCheckFail.png" after at most 30 seconds
