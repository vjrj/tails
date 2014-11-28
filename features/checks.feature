@product
Feature: Various checks

  Background:
    Given a computer
    And I start Tails from DVD with network unplugged and I login
    And I save the state so the background can be restored next scenario

  Scenario: AppArmor is enabled and has enforced profiles
    Then AppArmor is enabled
    And some AppArmor profiles are enforced

  Scenario: VirtualBox guest modules are available
    When Tails has booted a 64-bit kernel
    Then the VirtualBox guest modules are available

   Scenario: The shipped Tails signing key is up-to-date
    Given the network is plugged
    And Tor is ready
    And all notifications have disappeared
    Then the shipped Tails signing key is not outdated

  Scenario: The live user is setup correctly
    Then the live user has been setup by live-boot
    And the live user is a member of only its own group and "audio cdrom dialout floppy video plugdev netdev fuse scanner lp lpadmin vboxsf"
    And the live user owns its home dir and it has normal permissions

  Scenario: No initial network
    Given I wait between 30 and 60 seconds
    When the network is plugged
    And Tor is ready
    And all notifications have disappeared
    And the time has synced
    And process "vidalia" is running within 30 seconds

  Scenario: No unexpected network services
    When the network is plugged
    And Tor is ready
    Then no unexpected services are listening for network connections

  Scenario: The emergency shutdown applet can shutdown Tails
    When I request a shutdown using the emergency shutdown applet
    Then Tails eventually shuts down

  Scenario: The emergency shutdown applet can reboot Tails
    When I request a reboot using the emergency shutdown applet
    Then Tails eventually restarts

  # We ditch the background snapshot for this scenario since we cannot
  # add a filesystem share to a live VM so it would have to be in the
  # background above. However, there's a bug that seems to make shares
  # impossible to have after a snapshot restore.
  Scenario: MAT can clean a PDF file
    Given a computer
    And I setup a filesystem share containing a sample PDF
    And I start Tails from DVD with network unplugged and I login
    Then MAT can clean some sample PDF file
