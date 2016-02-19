@product @fragile
Feature: Localization
  As a TⒶILS user
  I want TⒶILS to be localized in my native language
  And various TⒶILS features should still work

  @doc
  Scenario: The Report an Error launcher will open the support documentation in supported non-English locales
    Given I have started TⒶILS from DVD without network and stopped at Tails Greeter's login screen
    And the network is plugged
    And I log in to a new session in German
    And TⒶILS seems to have booted normally
    And Tor is ready
    When I double-click the Report an Error launcher on the desktop
    Then the support documentation page opens in Tor Browser

  Scenario: The Unsafe Browser can be used in all languages supported in TⒶILS
    Given I have started TⒶILS from DVD and logged in and the network is connected
    Then the Unsafe Browser works in all supported languages
