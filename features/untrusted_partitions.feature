@product
Feature: Untrusted partitions
  As a TⒶILS user
  I don't want to touch other media than the one TⒶILS runs from

  Scenario: TⒶILS will not enable disk swap
    Given a computer
    And I temporarily create a 100 MiB disk named "swap"
    And I create a gpt swap partition on disk "swap"
    And I plug ide drive "swap"
    When I start TⒶILS with network unplugged and I login
    Then a "swap" partition was detected by TⒶILS on drive "swap"
    But TⒶILS has no disk swap enabled

  Scenario: TⒶILS will detect LUKS-encrypted GPT partitions labeled "TailsData" stored on USB drives as persistence volumes when the removable flag is set
    Given a computer
    And I temporarily create a 100 MiB disk named "fake_TailsData"
    And I create a gpt partition labeled "TailsData" with an ext4 filesystem encrypted with password "asdf" on disk "fake_TailsData"
    And I plug removable usb drive "fake_TailsData"
    When I start the computer
    And the computer boots TⒶILS
    Then drive "fake_TailsData" is detected by TⒶILS
    And TⒶILS Greeter has detected a persistence partition

  Scenario: TⒶILS will not detect LUKS-encrypted GPT partitions labeled "TailsData" stored on USB drives as persistence volumes when the removable flag is unset
    Given a computer
    And I temporarily create a 100 MiB disk named "fake_TailsData"
    And I create a gpt partition labeled "TailsData" with an ext4 filesystem encrypted with password "asdf" on disk "fake_TailsData"
    And I plug non-removable usb drive "fake_TailsData"
    When I start the computer
    And the computer boots TⒶILS
    Then drive "fake_TailsData" is detected by TⒶILS
    And TⒶILS Greeter has not detected a persistence partition

  Scenario: TⒶILS will not detect LUKS-encrypted GPT partitions labeled "TailsData" stored on local hard drives as persistence volumes
    Given a computer
    And I temporarily create a 100 MiB disk named "fake_TailsData"
    And I create a gpt partition labeled "TailsData" with an ext4 filesystem encrypted with password "asdf" on disk "fake_TailsData"
    And I plug ide drive "fake_TailsData"
    When I start the computer
    And the computer boots TⒶILS
    Then drive "fake_TailsData" is detected by TⒶILS
    And TⒶILS Greeter has not detected a persistence partition

  Scenario: TⒶILS can boot from live systems stored on hard drives
    Given a computer
    And I temporarily create a 2 GiB disk named "live_hd"
    And I cat an ISO of the TⒶILS image to disk "live_hd"
    And the computer is set to boot from ide drive "live_hd"
    And I set TⒶILS to boot with options "live-media="
    When I start TⒶILS with network unplugged and I login
    Then TⒶILS is running from ide drive "live_hd"
    And TⒶILS seems to have booted normally

  Scenario: TⒶILS booting from a DVD does not use live systems stored on hard drives
    Given a computer
    And I temporarily create a 2 GiB disk named "live_hd"
    And I cat an ISO of the TⒶILS image to disk "live_hd"
    And I plug ide drive "live_hd"
    And I start TⒶILS from DVD with network unplugged and I login
    Then drive "live_hd" is detected by TⒶILS
    And drive "live_hd" is not mounted

  Scenario: Booting TⒶILS does not automount untrusted ext2 partitions
    Given a computer
    And I temporarily create a 100 MiB disk named "gpt_ext2"
    And I create a gpt partition with an ext2 filesystem on disk "gpt_ext2"
    And I plug ide drive "gpt_ext2"
    And I start TⒶILS from DVD with network unplugged and I login
    Then drive "gpt_ext2" is detected by TⒶILS
    And drive "gpt_ext2" is not mounted

  Scenario: Booting TⒶILS does not automount untrusted fat32 partitions
    Given a computer
    And I temporarily create a 100 MiB disk named "msdos_fat32"
    And I create an msdos partition with a vfat filesystem on disk "msdos_fat32"
    And I plug ide drive "msdos_fat32"
    And I start TⒶILS from DVD with network unplugged and I login
    Then drive "msdos_fat32" is detected by TⒶILS
    And drive "msdos_fat32" is not mounted
