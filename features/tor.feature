@product
Feature: Tor is configured properly
  As a Tails user
  I want all direct Internet connections I do by mistake to be blocked
  And I want my Torified sessions to be sensibly isolated from each other to prevent identity correlation

  Background:
    Given a computer
    When I start Tails from DVD and I login
    And I save the state so the background can be restored next scenario

  Scenario: The firewall configuration is very restrictive
    Then the firewall's policy is to drop all IPv4 traffic
    And the firewall is configured to only allow the clearnet and debian-tor users to connect directly to the Internet over IPv4
    And the firewall's NAT rules only redirect traffic for Tor's TransPort and DNSPort
    And the firewall is configured to block all IPv6 traffic

  @check_tor_leaks
  Scenario: The Tor enforcement is effective at blocking untorified TCP connection attempts
    When I open an untorified TCP connections to 1.2.3.4 on port 42 that is expected to fail
    Then the untorified connection fails
    And the untorified connection is logged as dropped by the firewall

  @check_tor_leaks
  Scenario: The Tor enforcement is effective at blocking untorified UDP connection attempts
    When I open an untorified UDP connections to 1.2.3.4 on port 42 that is expected to fail
    Then the untorified connection fails
    And the untorified connection is logged as dropped by the firewall

  @check_tor_leaks
  Scenario: The Tor enforcement is effective at blocking untorified ICMP connection attempts
    When I open an untorified ICMP connections to 1.2.3.4 that is expected to fail
    Then the untorified connection fails
    And the untorified connection is logged as dropped by the firewall

  @check_tor_leaks
  Scenario: tails-security-check is using the Tails-specific SocksPort
    When I monitor the network connections of tails-security-check
    And I re-run tails-security-check
    Then I see that tails-security-check is properly stream isolated

  @check_tor_leaks
  Scenario: htpdate is using the Tails-specific SocksPort
    When I monitor the network connections of htpdate
    And I re-run htpdate
    Then I see that htpdate is properly stream isolated

  @check_tor_leaks
  Scenario: tails-upgrade-frontend-wrapper is using the Tails-specific SocksPort
    When I monitor the network connections of tails-upgrade-frontend-wrapper
    And I re-run tails-upgrade-frontend-wrapper
    Then I see that tails-upgrade-frontend-wrapper is properly stream isolated

  @check_tor_leaks
  Scenario: The Tor Browser is using the web browser-specific SocksPort
    When I monitor the network connections of Tor Browser
    And I start the Tor Browser
    And the Tor Browser has started and loaded the startup page
    Then I see that Tor Browser is properly stream isolated

  @check_tor_leaks
  Scenario: Gobby is using the default SocksPort
    When I monitor the network connections of Gobby
    And I start "Gobby" via the GNOME "Internet" applications menu
    And I connect Gobby to "gobby.debian.org"
    Then I see that Gobby is properly stream isolated

  @check_tor_leaks
  Scenario: SSH is using the default SocksPort
    When I monitor the network connections of SSH
    And I run "ssh lizard.tails.boum.org" in GNOME Terminal
    And I see "SSHAuthVerification.png" after at most 60 seconds
    Then I see that SSH is properly stream isolated

  @check_tor_leaks
  Scenario: whois lookups use the default SocksPort
    When I monitor the network connections of whois
    And I query the whois directory service for "boum.org"
    And the whois command is successful
    Then I see that whois is properly stream isolated

  @check_tor_leaks
  Scenario: Explicitly torify-wrapped applications are using the default SocksPort
    When I monitor the network connections of Gobby
    And I run "torify /usr/bin/gobby-0.5" in GNOME Terminal
    And I connect Gobby to "gobby.debian.org"
    Then I see that Gobby is properly stream isolated

  @check_tor_leaks
  Scenario: Explicitly torsocks-wrapped applications are using the default SocksPort
    When I monitor the network connections of Gobby
    And I run "torsocks /usr/bin/gobby-0.5" in GNOME Terminal
    And I connect Gobby to "gobby.debian.org"
    Then I see that Gobby is properly stream isolated

  Scenario: The system DNS is always set up to use Tor's DNSPort
    Given a computer
    And the network is unplugged
    And I start the computer
    And the computer boots Tails
    And I log in to a new session
    And GNOME has started
    And the system DNS is using the local DNS resolver
    And the network is plugged
    And Tor is ready
    Then the system DNS is still using the local DNS resolver
