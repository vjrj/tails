@product
Feature: Untrusted partitions
  As a Tails user
  I don't want to touch other media than the one Tails runs from

  @keep_volumes
  Scenario: Tails can boot from live systems stored on hard drives
    Given a computer
    And I create a 2 GiB disk named "live_hd"
    And I cat an ISO hybrid of the Tails image to disk "live_hd"
    And the computer is set to boot from ide drive "live_hd"
    And I set Tails to boot with options "live-media="
    And I start Tails from DVD with network unplugged and I login
    Then Tails seems to have booted normally

  Scenario: Tails booting from a DVD does not use live systems stored on hard drives
    Given a computer
    And I plug ide drive "live_hd"
    And I start Tails from DVD with network unplugged and I login
    Then drive "live_hd" is detected by Tails
    And drive "live_hd" is not mounted

  Scenario: Booting Tails does not automount untrusted ext2 partitions
    Given a computer
    And I create a 100 MiB disk named "gpt_ext2"
    And I create a gpt label on disk "gpt_ext2"
    And I create a ext2 filesystem on disk "gpt_ext2"
    And I plug ide drive "gpt_ext2"
    And I start Tails from DVD with network unplugged and I login
    Then drive "gpt_ext2" is detected by Tails
    And drive "gpt_ext2" is not mounted

  Scenario: Booting Tails does not automount untrusted fat32 partitions
    Given a computer
    And I create a 100 MiB disk named "msdos_fat32"
    And I create a msdos label on disk "msdos_fat32"
    And I create a fat32 filesystem on disk "msdos_fat32"
    And I plug ide drive "msdos_fat32"
    And I start Tails from DVD with network unplugged and I login
    Then drive "msdos_fat32" is detected by Tails
    And drive "msdos_fat32" is not mounted
