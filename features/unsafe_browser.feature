@product
Feature: Browsing the web using the Unsafe Browser
  As a Tails user
  when I browse the web using the Unsafe Browser
  I should have direct access to the web

  Background:
    Given a computer
    And I start the computer
    And the computer boots Tails
    And I log in to a new session
    And GNOME has started
    And Tor is ready
    And all notifications have disappeared
    And available upgrades have been checked
    And I save the state so the background can be restored next scenario

  Scenario: Starting the Unsafe Browser works as it should.
    When I successfully start the Unsafe Browser
    Then the Unsafe Browser runs as the expected user
    And the Unsafe Browser has a red theme
    And the Unsafe Browser shows a warning as its start page
    And the Unsafe Browser has no plugins installed
    And the Unsafe Browser has no add-ons installed
    And the Unsafe Browser has only Firefox's default bookmarks configured
    And the Unsafe Browser has no proxy configured
    And the Unsafe Browser uses all expected TBB shared libraries

  Scenario: Starting the Unsafe Browser works in Arabic
    When I start the Unsafe Browser in the "ar_EG" locale
    Then the Unsafe Browser has started

  Scenario: Starting the Unsafe Browser works in Brazilian Portuguese
    When I start the Unsafe Browser in the "pt_BR" locale
    Then the Unsafe Browser has started

  Scenario: Starting the Unsafe Browser works in Chinese
    When I start the Unsafe Browser in the "zh_CN" locale
    Then the Unsafe Browser has started

  Scenario: Starting the Unsafe Browser works in Dutch
    When I start the Unsafe Browser in the "nl_NL" locale
    Then the Unsafe Browser has started

  Scenario: Starting the Unsafe Browser works in Farsi
    When I start the Unsafe Browser in the "fa_IR" locale
    Then the Unsafe Browser has started

  Scenario: Starting the Unsafe Browser works in French
    When I start the Unsafe Browser in the "fr_FR" locale
    Then the Unsafe Browser has started

  Scenario: Starting the Unsafe Browser works in German
    When I start the Unsafe Browser in the "de_DE" locale
    Then the Unsafe Browser has started

  Scenario: Starting the Unsafe Browser works in Italian
    When I start the Unsafe Browser in the "it_IT" locale
    Then the Unsafe Browser has started

  Scenario: Starting the Unsafe Browser works in Korean
    When I start the Unsafe Browser in the "kr_KR" locale
    Then the Unsafe Browser has started

  Scenario: Starting the Unsafe Browser works in Polish
    When I start the Unsafe Browser in the "pl_PL" locale
    Then the Unsafe Browser has started

  Scenario: Starting the Unsafe Browser works in Portuguese
    When I start the Unsafe Browser in the "pt_PT" locale
    Then the Unsafe Browser has started

  Scenario: Starting the Unsafe Browser works in Russian
    When I start the Unsafe Browser in the "ru_RU" locale
    Then the Unsafe Browser has started

  Scenario: Starting the Unsafe Browser works in Turkish
    When I start the Unsafe Browser in the "tr_TR" locale
    Then the Unsafe Browser has started

  Scenario: Starting the Unsafe Browser works in Vietnamese
    When I start the Unsafe Browser in the "vi_VN" locale
    Then the Unsafe Browser has started

  Scenario: Closing the Unsafe Browser shows a stop notification and properly tears down the chroot.
    When I successfully start the Unsafe Browser
    And I close the Unsafe Browser
    Then I see the Unsafe Browser stop notification
    And the Unsafe Browser chroot is torn down

  Scenario: Starting a second instance of the Unsafe Browser results in an error message being shown.
    When I successfully start the Unsafe Browser
    And I start the Unsafe Browser
    Then I see a warning about another instance already running

  Scenario: Opening check.torproject.org in the Unsafe Browser shows the red onion and a warning message.
    When I successfully start the Unsafe Browser
    And I open the address "https://check.torproject.org" in the Unsafe Browser
    Then I see "UnsafeBrowserTorCheckFail.png" after at most 60 seconds
    And the clearnet user has sent packets out to the Internet

  Scenario: The Unsafe Browser cannot be configured to use Tor and other local proxies.
    When I successfully start the Unsafe Browser
    Then I cannot configure the Unsafe Browser to use any local proxies

  Scenario: The Unsafe Browser will not make any connections to the Internet which are not user initiated
    Given I capture all network traffic
    And Tor is ready
    And I configure the Unsafe Browser to check for updates more frequently
    But checking for updates is disabled in the Unsafe Browser's configuration
    When I successfully start the Unsafe Browser
    Then the Unsafe Browser has started
    And I wait between 60 and 120 seconds
    And the clearnet user has not sent packets out to the Internet
    And all Internet traffic has only flowed through Tor

  Scenario: Starting the Unsafe Browser without a network connection results in a complaint about no DNS server being configured
    Given a computer
    And I start Tails from DVD with network unplugged and I login
    When I start the Unsafe Browser
    Then the Unsafe Browser complains that no DNS server is configured
