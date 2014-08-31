@product
Feature: Browsing the web using Iceweasel
  As a Tails user
  when I browse the web using Iceweasel
  all Internet traffic should flow only through Tor

  Background:
    Given a computer
    And I capture all network traffic
    And I start the computer
    And the computer boots Tails
    And I log in to a new session
    And GNOME has started
    And Tor is ready
    And available upgrades have been checked
    And all notifications have disappeared
    And I save the state so the background can be restored next scenario

  Scenario: Opening check.torproject.org in Iceweasel shows the green onion and the congratulations message
    When I start Iceweasel
    And Iceweasel has started and is not loading a web page
    And I open the address "https://check.torproject.org" in Iceweasel
    Then I see "IceweaselTorCheck.png" after at most 180 seconds
    And all Internet traffic has only flowed through Tor

  Scenario: Iceweasel should not have any plugins enabled
    When I start Iceweasel
    And Iceweasel has started and is not loading a web page
    And I open the address "about:plugins" in Iceweasel
    Then I see "IceweaselNoPlugins.png" after at most 60 seconds
