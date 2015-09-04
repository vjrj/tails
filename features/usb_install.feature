@product
Feature: Installing Tails to a USB drive
  As a Tails user
  I want to install Tails to a suitable USB drive

  Scenario: Try to "Upgrade from ISO" Tails to a pristine USB drive
    Given a computer
    And I setup a filesystem share containing the Tails ISO
    And I start Tails from DVD with network unplugged and I login
    And I create a 4 GiB disk named "pristine"
    And I plug USB drive "pristine"
    And I start Tails Installer in "Upgrade from ISO" mode
    Then a suitable USB device is not found
    And I am told that the destination device cannot be upgraded

  Scenario: Try to "Clone & Upgrade" Tails to a pristine USB drive
    Given a computer
    And I start Tails from DVD with network unplugged and I login
    And I create a 4 GiB disk named "pristine"
    And I plug USB drive "pristine"
    And I start Tails Installer in "Upgrade from ISO" mode
    Then a suitable USB device is not found
    And I am told that the destination device cannot be upgraded

  Scenario: Try to "Upgrade from ISO" Tails to a USB drive with GPT and a FAT partition
    Given a computer
    And I setup a filesystem share containing the Tails ISO
    And I start Tails from DVD with network unplugged and I login
    And I create a 4 GiB disk named "gptfat"
    And I create a gpt partition with a vfat filesystem on disk "gptfat"
    And I plug USB drive "gptfat"
    And I start Tails Installer in "Upgrade from ISO" mode
    Then a suitable USB device is not found
    And I am told that the destination device cannot be upgraded

  Scenario: Try to "Clone & Upgrade" Tails to a USB drive with GPT and a FAT partition
    Given a computer
    And I start Tails from DVD with network unplugged and I login
    And I create a 4 GiB disk named "gptfat"
    And I create a gpt partition with a vfat filesystem on disk "gptfat"
    And I plug USB drive "gptfat"
    And I start Tails Installer in "Upgrade from ISO" mode
    Then a suitable USB device is not found
    And I am told that the destination device cannot be upgraded

  Scenario: Try installing Tails to a too small USB drive
    Given Tails has booted from DVD without network and logged in
    And I temporarily create a 2 GiB disk named "too-small-device"
    And I start Tails Installer in "Clone & Install" mode
    But a suitable USB device is not found
    When I plug USB drive "too-small-device"
    Then Tails Installer detects that a device is too small
    And a suitable USB device is not found

  Scenario: Test that Tails installer can detect when a target USB drive is inserted or removed
    Given Tails has booted from DVD without network and logged in
    And I temporarily create a 4 GiB disk named "temp"
    And I start Tails Installer in "Clone & Install" mode
    But a suitable USB device is not found
    When I plug USB drive "temp"
    Then the "temp" USB drive is selected
    When I unplug USB drive "temp"
    Then no USB drive is selected
    And a suitable USB device is not found

  Scenario: Booting Tails from a USB drive without a persistent partition
    Given Tails has booted without network from a USB drive without a persistent partition and stopped at Tails Greeter's login screen
    When I log in to a new session
    Then Tails seems to have booted normally
    And Tails is running from USB drive "current"
    And the persistent Tor Browser directory does not exist
    And there is no persistence partition on USB drive "current"

  Scenario: Booting Tails from a USB drive in UEFI mode
    Given Tails has booted without network from a USB drive without a persistent partition and stopped at Tails Greeter's login screen
    Then I power off the computer
    Given the computer is set to boot in UEFI mode
    When I start Tails from USB drive "current" with network unplugged and I login
    Then the boot device has safe access rights
    And Tails is running from USB drive "current"
    And the boot device has safe access rights
    And Tails has started in UEFI mode

  @keep_volumes
  Scenario: Booting Tails from a USB drive without a persistent partition and creating one
    Given a computer
    And I start Tails from USB drive "current" with network unplugged and I login
    Then the boot device has safe access rights
    And process "udev-watchdog" is running
    And udev-watchdog is monitoring the correct device
    And Tails is running from USB drive "current"
    And the boot device has safe access rights
    And there is no persistence partition on USB drive "current"
    And the persistent Tor Browser directory does not exist
    And I create a persistent partition with password "asdf"
    Then a Tails persistence partition with password "asdf" exists on USB drive "current"
    And I shutdown Tails and wait for the computer to power off

  @keep_volumes
  Scenario: Booting Tails from a USB drive with a disabled persistent partition
    Given a computer
    And I start Tails from USB drive "current" with network unplugged and I login
    Then Tails is running from USB drive "current"
    And the boot device has safe access rights
    And persistence is disabled
    But a Tails persistence partition with password "asdf" exists on USB drive "current"

  @keep_volumes
  Scenario: The persistent Tor Browser directory is usable
    Given a computer
    And I start Tails from USB drive "current" and I login with persistence password "asdf"
    And Tails is running from USB drive "current"
    And Tor is ready
    And available upgrades have been checked
    And all notifications have disappeared
    Then the persistent Tor Browser directory exists
    And there is a GNOME bookmark for the persistent Tor Browser directory
    When I start the Tor Browser
    And the Tor Browser has started and loaded the startup page
    And I can save the current page as "index.html" to the persistent Tor Browser directory
    When I open the address "file:///home/amnesia/Persistent/Tor Browser/index.html" in the Tor Browser
    Then I see "TorBrowserSavedStartupPage.png" after at most 10 seconds
    And I can print the current page as "output.pdf" to the persistent Tor Browser directory

  @keep_volumes
  Scenario: Persistent browser bookmarks
    Given a computer
    And the computer is set to boot from USB drive "current"
    And the network is unplugged
    When I start the computer
    And the computer boots Tails
    And Tails is running from USB drive "current"
    And the boot device has safe access rights
    And I enable persistence with password "asdf"
    And I log in to a new session
    And the Tails desktop is ready
    And all notifications have disappeared
    And all persistence presets are enabled
    And all persistent filesystems have safe access rights
    And all persistence configuration files have safe access rights
    And all persistent directories have safe access rights
    And I start the Tor Browser in offline mode
    And the Tor Browser has started in offline mode
    And I add a bookmark to eff.org in the Tor Browser
    And I warm reboot the computer
    And the computer reboots Tails
    And I enable read-only persistence with password "asdf"
    And I log in to a new session
    And the Tails desktop is ready
    And I start the Tor Browser in offline mode
    And the Tor Browser has started in offline mode
    Then the Tor Browser has a bookmark to eff.org

  @keep_volumes
  Scenario: Writing files to a read/write-enabled persistent partition
    Given a computer
    And I start Tails from USB drive "current" with network unplugged and I login with persistence password "asdf"
    Then Tails is running from USB drive "current"
    And the boot device has safe access rights
    And all persistence presets are enabled
    And I write some files expected to persist
    And all persistent filesystems have safe access rights
    And all persistence configuration files have safe access rights
    And all persistent directories have safe access rights
    And I take note of which persistence presets are available
    And I shutdown Tails and wait for the computer to power off
    Then only the expected files are present on the persistence partition encrypted with password "asdf" on USB drive "current"

  @keep_volumes
  Scenario: Writing files to a read-only-enabled persistent partition
    Given a computer
    And I start Tails from USB drive "current" with network unplugged and I login with read-only persistence password "asdf"
    Then Tails is running from USB drive "current"
    And the boot device has safe access rights
    And all persistence presets are enabled
    And there is no GNOME bookmark for the persistent Tor Browser directory
    And I write some files not expected to persist
    And I remove some files expected to persist
    And I take note of which persistence presets are available
    And I shutdown Tails and wait for the computer to power off
    Then only the expected files are present on the persistence partition encrypted with password "asdf" on USB drive "current"

  @keep_volumes
  Scenario: Deleting a Tails persistent partition
    Given a computer
    And I start Tails from USB drive "current" with network unplugged and I login
    Then Tails is running from USB drive "current"
    And the boot device has safe access rights
    And persistence is disabled
    But a Tails persistence partition with password "asdf" exists on USB drive "current"
    And all notifications have disappeared
    When I delete the persistent partition
    Then there is no persistence partition on USB drive "current"

  @keep_volumes
  Scenario: Installing an old version of Tails to a pristine USB drive
    Given a computer
    And the computer is set to boot from the old Tails DVD
    And the network is unplugged
    And I start the computer
    When the computer boots Tails
    And I log in to a new session
    And the Tails desktop is ready
    And all notifications have disappeared
    And I create a 4 GiB disk named "old"
    And I plug USB drive "old"
    And I "Clone & Install" Tails to USB drive "old"
    Then the running Tails is installed on USB drive "old"
    But there is no persistence partition on USB drive "old"
    And I unplug USB drive "old"

  @keep_volumes
  Scenario: Creating a persistent partition with the old Tails USB installation
    Given a computer
    And I start Tails from USB drive "old" with network unplugged and I login
    Then Tails is running from USB drive "old"
    And I create a persistent partition with password "asdf"
    And I take note of which persistence presets are available
    Then a Tails persistence partition with password "asdf" exists on USB drive "old"
    And I shutdown Tails and wait for the computer to power off

  @keep_volumes
  Scenario: Writing files to a read/write-enabled persistent partition with the old Tails USB installation
    Given a computer
    And I start Tails from USB drive "old" with network unplugged and I login with persistence password "asdf"
    Then Tails is running from USB drive "old"
    And all persistence presets are enabled
    And I write some files expected to persist
    And all persistent filesystems have safe access rights
    And all persistence configuration files have safe access rights
    And all persistent directories from the old Tails version have safe access rights
    And I take note of which persistence presets are available
    And I shutdown Tails and wait for the computer to power off
    Then only the expected files are present on the persistence partition encrypted with password "asdf" on USB drive "old"

  @keep_volumes
  Scenario: Upgrading an old Tails USB installation from a Tails DVD
    Given a computer
    And I clone USB drive "old" to a new USB drive "to_upgrade"
    And I start Tails from DVD with network unplugged and I login
    And I plug USB drive "to_upgrade"
    And I "Clone & Upgrade" Tails to USB drive "to_upgrade"
    Then the running Tails is installed on USB drive "to_upgrade"
    And I unplug USB drive "to_upgrade"

  @keep_volumes
  Scenario: Booting Tails from a USB drive upgraded from DVD with persistence enabled
    Given a computer
    And I start Tails from USB drive "to_upgrade" with network unplugged and I login with persistence password "asdf"
    Then all persistence presets from the old Tails version are enabled
    Then Tails is running from USB drive "to_upgrade"
    And the boot device has safe access rights
    And the expected persistent files created with the old Tails version are present in the filesystem
    And all persistent directories from the old Tails version have safe access rights

  @keep_volumes
  Scenario: Upgrading an old Tails USB installation from another Tails USB drive
    Given a computer
    And I clone USB drive "old" to a new USB drive "to_upgrade"
    And I start Tails from USB drive "current" with network unplugged and I login
    Then Tails is running from USB drive "current"
    And the boot device has safe access rights
    And I plug USB drive "to_upgrade"
    And I "Clone & Upgrade" Tails to USB drive "to_upgrade"
    Then the running Tails is installed on USB drive "to_upgrade"
    And I unplug USB drive "to_upgrade"
    And I unplug USB drive "current"

  @keep_volumes
  Scenario: Booting Tails from a USB drive upgraded from USB with persistence enabled
    Given a computer
    And I start Tails from USB drive "to_upgrade" with network unplugged and I login with persistence password "asdf"
    Then all persistence presets from the old Tails version are enabled
    And Tails is running from USB drive "to_upgrade"
    And the boot device has safe access rights
    And the expected persistent files created with the old Tails version are present in the filesystem
    And all persistent directories from the old Tails version have safe access rights

  @keep_volumes
  Scenario: Upgrading an old Tails USB installation from an ISO image, running on the old version
    Given a computer
    And I clone USB drive "old" to a new USB drive "to_upgrade"
    And I setup a filesystem share containing the Tails ISO
    When I start Tails from USB drive "old" with network unplugged and I login
    And I plug USB drive "to_upgrade"
    And I do a "Upgrade from ISO" on USB drive "to_upgrade"
    Then the ISO's Tails is installed on USB drive "to_upgrade"
    And I unplug USB drive "to_upgrade"

  @keep_volumes
  Scenario: Upgrading an old Tails USB installation from an ISO image, running on the new version
    Given a computer
    And I clone USB drive "old" to a new USB drive "to_upgrade"
    And I setup a filesystem share containing the Tails ISO
    And I start Tails from DVD with network unplugged and I login
    And I plug USB drive "to_upgrade"
    And I do a "Upgrade from ISO" on USB drive "to_upgrade"
    Then the ISO's Tails is installed on USB drive "to_upgrade"
    And I unplug USB drive "to_upgrade"

  Scenario: Booting a USB drive upgraded from ISO with persistence enabled
    Given a computer
    And I temporarily create a 4 GiB disk named "mbr"
    And I create a msdos label on disk "mbr"
    And I start Tails from DVD with network unplugged and I login
    And I plug USB drive "mbr"
    And I "Clone & Install" Tails to USB drive "mbr"
    Then the running Tails is installed on USB drive "mbr"
    But there is no persistence partition on USB drive "mbr"
    When I shutdown Tails and wait for the computer to power off
    And I start Tails from USB drive "mbr" with network unplugged and I login
    Then Tails is running from USB drive "mbr"
    And the boot device has safe access rights
    And there is no persistence partition on USB drive "mbr"

  Scenario: Cat:ing a Tails isohybrid to a USB drive and booting it, then trying to upgrading it but ending up having to do a fresh installation, which boots
    Given a computer
    And I create a 4 GiB disk named "isohybrid"
    And I cat an ISO of the Tails image to disk "isohybrid"
    And I start Tails from USB drive "isohybrid" with network unplugged and I login
    Then Tails is running from USB drive "isohybrid"
    When I shutdown Tails and wait for the computer to power off
    And I start Tails from DVD with network unplugged and I login
    And I try a "Clone & Upgrade" Tails to USB drive "isohybrid"
    Then I am suggested to do a "Clone & Install"
    When I kill the process "liveusb-creator"
    And I "Clone & Install" Tails to USB drive "isohybrid"
    Then the running Tails is installed on USB drive "isohybrid"
    But there is no persistence partition on USB drive "isohybrid"
    When I shutdown Tails and wait for the computer to power off
    And I start Tails from USB drive "isohybrid" with network unplugged and I login
    Then Tails is running from USB drive "isohybrid"
    And the boot device has safe access rights
    And there is no persistence partition on USB drive "isohybrid"
