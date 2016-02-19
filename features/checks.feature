@product
Feature: Various checks

  Scenario: AppArmor is enabled and has enforced profiles
    Given I have started TⒶILS from DVD without network and logged in
    Then AppArmor is enabled
    And some AppArmor profiles are enforced

  Scenario: A screenshot is taken when the PRINTSCREEN key is pressed
    Given I have started TⒶILS from DVD without network and logged in
    And there is no screenshot in the live user's Pictures directory
    When I press the "PRINTSCREEN" key
    Then a screenshot is saved to the live user's Pictures directory

  Scenario: VirtualBox guest modules are available
    Given I have started TⒶILS from DVD without network and logged in
    When TⒶILS has booted a 64-bit kernel
    Then the VirtualBox guest modules are available

  Scenario: The shipped TⒶILS OpenPGP keys are up-to-date
    Given I have started TⒶILS from DVD without network and logged in
    Then the OpenPGP keys shipped with TⒶILS will be valid for the next 3 months

  Scenario: The TⒶILS Debian repository key is up-to-date
    Given I have started TⒶILS from DVD without network and logged in
    Then the shipped Debian repository key will be valid for the next 3 months

  @doc @fragile
  Scenario: The "Report an Error" launcher will open the support documentation
    Given I have started TⒶILS from DVD without network and logged in
    And the network is plugged
    And Tor is ready
    And all notifications have disappeared
    When I double-click the Report an Error launcher on the desktop
    Then the support documentation page opens in Tor Browser

  Scenario: The live user is setup correctly
    Given I have started TⒶILS from DVD without network and logged in
    Then the live user has been setup by live-boot
    And the live user is a member of only its own group and "audio cdrom dialout floppy video plugdev netdev scanner lp lpadmin vboxsf"
    And the live user owns its home dir and it has normal permissions

  @fragile
  Scenario: No initial network
    Given I have started TⒶILS from DVD without network and logged in
    And I wait between 30 and 60 seconds
    When the network is plugged
    And Tor is ready
    And all notifications have disappeared
    And the time has synced
    And process "vidalia" is running within 30 seconds

  @fragile
  Scenario: The 'Tor is ready' notification is shown when Tor has bootstrapped
    Given I have started TⒶILS from DVD without network and logged in
    And the network is plugged
    When I see the 'Tor is ready' notification
    Then Tor is ready

  @fragile
  Scenario: The tor process should be confined with Seccomp
    Given I have started TⒶILS from DVD without network and logged in
    And the network is plugged
    And Tor is ready
    Then the running process "tor" is confined with Seccomp in filter mode

  @fragile
  Scenario: No unexpected network services
    Given I have started TⒶILS from DVD without network and logged in
    When the network is plugged
    And Tor is ready
    Then no unexpected services are listening for network connections

  Scenario: The emergency shutdown applet can shutdown TⒶILS
    Given I have started TⒶILS from DVD without network and logged in
    When I request a shutdown using the emergency shutdown applet
    Then TⒶILS eventually shuts down

  Scenario: The emergency shutdown applet can reboot TⒶILS
    Given I have started TⒶILS from DVD without network and logged in
    When I request a reboot using the emergency shutdown applet
    Then TⒶILS eventually restarts

  Scenario: tails-debugging-info does not leak information
    Given I have started TⒶILS from DVD without network and logged in
    Then tails-debugging-info is not susceptible to symlink attacks

  Scenario: TⒶILS shuts down on DVD boot medium removal
    Given I have started TⒶILS from DVD without network and logged in
    When I eject the boot medium
    Then TⒶILS eventually shuts down

  #10720
  @fragile
  Scenario: TⒶILS shuts down on USB boot medium removal
    Given I have started TⒶILS without network from a USB drive without a persistent partition and logged in
    When I eject the boot medium
    Then TⒶILS eventually shuts down

  Scenario: The TⒶILS Greeter "disable all networking" option disables networking within Tails
    Given I have started TⒶILS from DVD without network and stopped at Tails Greeter's login screen
    And I enable more TⒶILS Greeter options
    And I disable all networking in the TⒶILS Greeter
    And I log in to a new session
    And the TⒶILS desktop is ready
    Then no network interfaces are enabled
