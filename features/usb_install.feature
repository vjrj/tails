@product
Feature: Installing TⒶILS to a USB drive
  As a TⒶILS user
  I want to install TⒶILS to a suitable USB drive

  Scenario: Try installing TⒶILS to a too small USB drive
    Given I have started TⒶILS from DVD without network and logged in
    And I temporarily create a 2 GiB disk named "too-small-device"
    And I start TⒶILS Installer in "Clone & Install" mode
    But a suitable USB device is not found
    When I plug USB drive "too-small-device"
    Then TⒶILS Installer detects that a device is too small
    And a suitable USB device is not found
    When I unplug USB drive "too-small-device"
    And I create a 4 GiB disk named "big-enough"
    And I plug USB drive "big-enough"
    Then the "big-enough" USB drive is selected

  Scenario: Detecting when a target USB drive is inserted or removed
    Given I have started TⒶILS from DVD without network and logged in
    And I temporarily create a 4 GiB disk named "temp"
    And I start TⒶILS Installer in "Clone & Install" mode
    But a suitable USB device is not found
    When I plug USB drive "temp"
    Then the "temp" USB drive is selected
    When I unplug USB drive "temp"
    Then no USB drive is selected
    And a suitable USB device is not found

  #10720: TⒶILS Installer freezes on Jenkins
  @fragile
  Scenario: Installing TⒶILS to a pristine USB drive
    Given I have started TⒶILS from DVD without network and logged in
    And I temporarily create a 4 GiB disk named "install"
    And I plug USB drive "install"
    And I "Clone & Install" TⒶILS to USB drive "install"
    Then the running TⒶILS is installed on USB drive "install"
    But there is no persistence partition on USB drive "install"

  #10720: TⒶILS Installer freezes on Jenkins
  @fragile
  Scenario: Booting TⒶILS from a USB drive without a persistent partition and creating one
    Given I have started TⒶILS without network from a USB drive without a persistent partition and stopped at Tails Greeter's login screen
    And I log in to a new session
    Then TⒶILS seems to have booted normally
    When I create a persistent partition
    Then a TⒶILS persistence partition exists on USB drive "__internal"

  #10720: TⒶILS Installer freezes on Jenkins
  @fragile
  Scenario: Booting TⒶILS from a USB drive without a persistent partition
    Given I have started TⒶILS without network from a USB drive without a persistent partition and stopped at Tails Greeter's login screen
    When I log in to a new session
    Then TⒶILS seems to have booted normally
    And TⒶILS is running from USB drive "__internal"
    And the persistent Tor Browser directory does not exist
    And there is no persistence partition on USB drive "__internal"

  #10720: TⒶILS Installer freezes on Jenkins
  @fragile
  Scenario: Booting TⒶILS from a USB drive in UEFI mode
    Given I have started TⒶILS without network from a USB drive without a persistent partition and stopped at Tails Greeter's login screen
    Then I power off the computer
    Given the computer is set to boot in UEFI mode
    When I start TⒶILS from USB drive "__internal" with network unplugged and I login
    Then the boot device has safe access rights
    And TⒶILS is running from USB drive "__internal"
    And the boot device has safe access rights
    And TⒶILS has started in UEFI mode

  #10720: TⒶILS Installer freezes on Jenkins
  @fragile
  Scenario: Installing TⒶILS to a USB drive with an MBR partition table but no partitions, and making sure that it boots
    Given I have started TⒶILS from DVD without network and logged in
    And I temporarily create a 4 GiB disk named "mbr"
    And I create a msdos label on disk "mbr"
    And I plug USB drive "mbr"
    And I "Clone & Install" TⒶILS to USB drive "mbr"
    Then the running TⒶILS is installed on USB drive "mbr"
    But there is no persistence partition on USB drive "mbr"
    When I shutdown TⒶILS and wait for the computer to power off
    And I start TⒶILS from USB drive "mbr" with network unplugged and I login
    Then TⒶILS is running from USB drive "mbr"
    And the boot device has safe access rights
    And there is no persistence partition on USB drive "mbr"

  #10720: TⒶILS Installer freezes on Jenkins
  @fragile
  Scenario: Cat:ing a TⒶILS isohybrid to a USB drive and booting it, then trying to upgrading it but ending up having to do a fresh installation, which boots
    Given a computer
    And I temporarily create a 4 GiB disk named "isohybrid"
    And I cat an ISO of the TⒶILS image to disk "isohybrid"
    And I start TⒶILS from USB drive "isohybrid" with network unplugged and I login
    Then TⒶILS is running from USB drive "isohybrid"
    When I shutdown TⒶILS and wait for the computer to power off
    And I start TⒶILS from DVD with network unplugged and I login
    And I try a "Clone & Upgrade" TⒶILS to USB drive "isohybrid"
    Then I am suggested to do a "Clone & Install"
    When I kill the process "tails-installer"
    And I "Clone & Install" TⒶILS to USB drive "isohybrid"
    Then the running TⒶILS is installed on USB drive "isohybrid"
    But there is no persistence partition on USB drive "isohybrid"
    When I shutdown TⒶILS and wait for the computer to power off
    And I start TⒶILS from USB drive "isohybrid" with network unplugged and I login
    Then TⒶILS is running from USB drive "isohybrid"
    And the boot device has safe access rights
    And there is no persistence partition on USB drive "isohybrid"
