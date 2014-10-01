@product @old_iso
Feature: Installing Tails to a USB drive, upgrading it, and using persistence
  As a Tails user
  I may want to install Tails to a USB drive
  and upgrade it to new Tails versions
  and use persistence

  @keep_volumes
  Scenario: Installing Tails to a pristine USB drive
    Given a computer
    And the computer is set to boot from the Tails DVD
    And the network is unplugged
    And I start the computer
    When the computer boots Tails
    And I log in to a new session
    And GNOME has started
    And all notifications have disappeared
    And I create a new 4 GiB USB drive named "current"
    And I plug USB drive "current"
    And I "Clone & Install" Tails to USB drive "current"
    Then the running Tails is installed on USB drive "current"
    But there is no persistence partition on USB drive "current"
    And I unplug USB drive "current"

  @keep_volumes
  Scenario: Booting Tails from a USB drive in UEFI mode
    Given a computer
    And the computer is set to boot from USB drive "current"
    And the computer is set to boot in UEFI mode
    And the network is unplugged
    When I start the computer
    And the computer boots Tails
    And the boot device has safe access rights
    And I log in to a new session
    And GNOME has started
    And all notifications have disappeared
    Then Tails seems to have booted normally
    And Tails is running from USB drive "current"
    And the boot device has safe access rights
    And Tails has started in UEFI mode

  @keep_volumes
  Scenario: Booting Tails from a USB drive without a persistent partition and creating one
    Given a computer
    And the computer is set to boot from USB drive "current"
    And the network is unplugged
    When I start the computer
    And the computer boots Tails
    And the boot device has safe access rights
    And I log in to a new session
    And GNOME has started
    And all notifications have disappeared
    Then Tails seems to have booted normally
    And Tails is running from USB drive "current"
    And the boot device has safe access rights
    And there is no persistence partition on USB drive "current"
    And I create a persistent partition with password "asdf"
    Then a Tails persistence partition with password "asdf" exists on USB drive "current"
    And I shutdown Tails and wait for the computer to power off

  @keep_volumes
  Scenario: Booting Tails from a USB drive with a disabled persistent partition
    Given a computer
    And the computer is set to boot from USB drive "current"
    And the network is unplugged
    When I start the computer
    And the computer boots Tails
    And I log in to a new session
    Then Tails seems to have booted normally
    And Tails is running from USB drive "current"
    And the boot device has safe access rights
    And persistence is disabled
    But a Tails persistence partition with password "asdf" exists on USB drive "current"

  @keep_volumes
  Scenario: Writing files to a read/write-enabled persistent partition
    Given a computer
    And the computer is set to boot from USB drive "current"
    And the network is unplugged
    When I start the computer
    And the computer boots Tails
    And Tails is running from USB drive "current"
    And the boot device has safe access rights
    And I enable persistence with password "asdf"
    And I log in to a new session
    And GNOME has started
    And all notifications have disappeared
    And persistence is enabled
    And I write some files expected to persist
    And persistent filesystems have safe access rights
    And persistence configuration files have safe access rights
    And persistent directories have safe access rights
    And I shutdown Tails and wait for the computer to power off
    Then only the expected files should persist on USB drive "current"

  @keep_volumes
  Scenario: Writing files to a read-only-enabled persistent partition
    Given a computer
    And the computer is set to boot from USB drive "current"
    And the network is unplugged
    When I start the computer
    And the computer boots Tails
    And Tails is running from USB drive "current"
    And the boot device has safe access rights
    And I enable read-only persistence with password "asdf"
    And I log in to a new session
    And GNOME has started
    And all notifications have disappeared
    And persistence is enabled
    And I write some files not expected to persist
    And I remove some files expected to persist
    And I shutdown Tails and wait for the computer to power off
    Then only the expected files should persist on USB drive "current"

  @keep_volumes
  Scenario: Deleting a Tails persistent partition
    Given a computer
    And the computer is set to boot from USB drive "current"
    And the network is unplugged
    And I start the computer
    And the computer boots Tails
    And I log in to a new session
    And Tails is running from USB drive "current"
    And the boot device has safe access rights
    And Tails seems to have booted normally
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
    And GNOME has started
    And all notifications have disappeared
    And I create a new 4 GiB USB drive named "old"
    And I plug USB drive "old"
    And I "Clone & Install" Tails to USB drive "old"
    Then the running Tails is installed on USB drive "old"
    But there is no persistence partition on USB drive "old"
    And I unplug USB drive "old"

  @keep_volumes
  Scenario: Creating a persistent partition with the old Tails USB installation
    Given a computer
    And the computer is set to boot from USB drive "old"
    And the network is unplugged
    When I start the computer
    And the computer boots Tails
    And Tails is running from USB drive "old"
    And I log in to a new session
    And GNOME has started
    And all notifications have disappeared
    And I create a persistent partition with password "asdf"
    Then a Tails persistence partition with password "asdf" exists on USB drive "old"
    And I shutdown Tails and wait for the computer to power off

  @keep_volumes
  Scenario: Writing files to a read/write-enabled persistent partition with the old Tails USB installation
    Given a computer
    And the computer is set to boot from USB drive "old"
    And the network is unplugged
    When I start the computer
    And the computer boots Tails
    And Tails is running from USB drive "old"
    And I enable persistence with password "asdf"
    And I log in to a new session
    And GNOME has started
    And all notifications have disappeared
    And persistence is enabled
    And I write some files expected to persist
    And persistent filesystems have safe access rights
    And persistence configuration files have safe access rights
    And persistent directories have safe access rights
    And I shutdown Tails and wait for the computer to power off
    Then only the expected files should persist on USB drive "old"

  @keep_volumes
  Scenario: Upgrading an old Tails USB installation from a Tails DVD
    Given a computer
    And I clone USB drive "old" to a new USB drive "to_upgrade"
    And the computer is set to boot from the Tails DVD
    And the network is unplugged
    When I start the computer
    And the computer boots Tails
    And I log in to a new session
    And GNOME has started
    And all notifications have disappeared
    And I plug USB drive "to_upgrade"
    And I "Clone & Upgrade" Tails to USB drive "to_upgrade"
    Then the running Tails is installed on USB drive "to_upgrade"
    And I unplug USB drive "to_upgrade"

  @keep_volumes
  Scenario: Booting Tails from a USB drive upgraded from DVD with persistence enabled
    Given a computer
    And the computer is set to boot from USB drive "to_upgrade"
    And the network is unplugged
    When I start the computer
    And the computer boots Tails
    And I enable persistence with password "asdf"
    And I log in to a new session
    Then Tails seems to have booted normally
    And Tails is running from USB drive "to_upgrade"
    And the boot device has safe access rights
    And the expected persistent files are present in the filesystem
    And persistent directories have safe access rights

  @keep_volumes
  Scenario: Upgrading an old Tails USB installation from another Tails USB drive
    Given a computer
    And I clone USB drive "old" to a new USB drive "to_upgrade"
    And the computer is set to boot from USB drive "current"
    And the network is unplugged
    When I start the computer
    And the computer boots Tails
    And Tails is running from USB drive "current"
    And the boot device has safe access rights
    And I log in to a new session
    And GNOME has started
    And all notifications have disappeared
    And I plug USB drive "to_upgrade"
    And I "Clone & Upgrade" Tails to USB drive "to_upgrade"
    Then the running Tails is installed on USB drive "to_upgrade"
    And I unplug USB drive "to_upgrade"
    And I unplug USB drive "current"

  @keep_volumes
  Scenario: Booting Tails from a USB drive upgraded from USB with persistence enabled
    Given a computer
    And the computer is set to boot from USB drive "to_upgrade"
    And the network is unplugged
    When I start the computer
    And the computer boots Tails
    And I enable persistence with password "asdf"
    And I log in to a new session
    Then Tails seems to have booted normally
    And persistence is enabled
    And Tails is running from USB drive "to_upgrade"
    And the boot device has safe access rights
    And the expected persistent files are present in the filesystem
    And persistent directories have safe access rights

  @keep_volumes
  Scenario: Upgrading an old Tails USB installation from an ISO image, running on the old version
    Given a computer
    And I clone USB drive "old" to a new USB drive "to_upgrade"
    And the computer is set to boot from USB drive "old"
    And the network is unplugged
    And I setup a filesystem share containing the Tails ISO
    When I start the computer
    And the computer boots Tails
    And I log in to a new session
    And GNOME has started
    And all notifications have disappeared
    And I plug USB drive "to_upgrade"
    And I do a "Upgrade from ISO" on USB drive "to_upgrade"
    Then the ISO's Tails is installed on USB drive "to_upgrade"
    And I unplug USB drive "to_upgrade"

  @keep_volumes
  Scenario: Upgrading an old Tails USB installation from an ISO image, running on the new version
    Given a computer
    And I clone USB drive "old" to a new USB drive "to_upgrade"
    And the computer is set to boot from the Tails DVD
    And the network is unplugged
    And I setup a filesystem share containing the Tails ISO
    When I start the computer
    And the computer boots Tails
    And I log in to a new session
    And GNOME has started
    And all notifications have disappeared
    And I plug USB drive "to_upgrade"
    And I do a "Upgrade from ISO" on USB drive "to_upgrade"
    Then the ISO's Tails is installed on USB drive "to_upgrade"
    And I unplug USB drive "to_upgrade"

  Scenario: Booting a USB drive upgraded from ISO with persistence enabled
    Given a computer
    And the computer is set to boot from USB drive "to_upgrade"
    And the network is unplugged
    When I start the computer
    And the computer boots Tails
    And I enable persistence with password "asdf"
    And I log in to a new session
    Then Tails seems to have booted normally
    And persistence is enabled
    And Tails is running from USB drive "to_upgrade"
    And the boot device has safe access rights
    And the expected persistent files are present in the filesystem
    And persistent directories have safe access rights

  @keep_volumes
  Scenario: Installing Tails to a USB drive with an MBR partition table but no partitions
    Given a computer
    And I create a 4 GiB disk named "mbr"
    And I create a msdos label on disk "mbr"
    And the computer is set to boot from the Tails DVD
    And the network is unplugged
    And I start the computer
    When the computer boots Tails
    And I log in to a new session
    And GNOME has started
    And all notifications have disappeared
    And I plug USB drive "mbr"
    And I "Clone & Install" Tails to USB drive "mbr"
    Then the running Tails is installed on USB drive "mbr"
    But there is no persistence partition on USB drive "mbr"
    And I unplug USB drive "mbr"

  Scenario: Booting a USB drive that originally had an empty MBR partition table
    Given a computer
    And the computer is set to boot from USB drive "mbr"
    And the network is unplugged
    When I start the computer
    And the computer boots Tails
    And I log in to a new session
    Then Tails seems to have booted normally
    And Tails is running from USB drive "mbr"
    And the boot device has safe access rights
    And there is no persistence partition on USB drive "mbr"

  @keep_volumes
  Scenario: Cat:ing a Tails isohybrid to a USB drive and booting it
    Given a computer
    And I create a 4 GiB disk named "isohybrid"
    And I cat an ISO hybrid of the Tails image to disk "isohybrid"
    And the computer is set to boot from USB drive "isohybrid"
    And the network is unplugged
    When I start the computer
    And the computer boots Tails
    And I log in to a new session
    Then Tails seems to have booted normally
    And Tails is running from USB drive "isohybrid"

  @keep_volumes
  Scenario: Try upgrading but end up installing Tails to a USB drive containing a Tails isohybrid installation
    Given a computer
    And the computer is set to boot from the Tails DVD
    And the network is unplugged
    And I start the computer
    When the computer boots Tails
    And I log in to a new session
    And GNOME has started
    And all notifications have disappeared
    And I plug USB drive "isohybrid"
    And I try a "Clone & Upgrade" Tails to USB drive "isohybrid"
    But I am suggested to do a "Clone & Install"
    And I kill the process "liveusb-creator"
    And I "Clone & Install" Tails to USB drive "isohybrid"
    Then the running Tails is installed on USB drive "isohybrid"
    But there is no persistence partition on USB drive "isohybrid"
    And I unplug USB drive "isohybrid"

  Scenario: Booting a USB drive that originally had a isohybrid installation
    Given a computer
    And the computer is set to boot from USB drive "isohybrid"
    And the network is unplugged
    When I start the computer
    And the computer boots Tails
    And I log in to a new session
    Then Tails seems to have booted normally
    And Tails is running from USB drive "isohybrid"
    And the boot device has safe access rights
    And there is no persistence partition on USB drive "isohybrid"
