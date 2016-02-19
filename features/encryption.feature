@product
Feature: Encryption and verification using GnuPG
  As a TⒶILS user
  I want to be able to easily encrypt and sign messages using GnuPG
  And decrypt and verify GnuPG blocks

  Background:
    Given I have started TⒶILS from DVD without network and logged in
    And I generate an OpenPGP key named "test" with password "asdf"

  #10992
  @fragile
  Scenario: Encryption and decryption using TⒶILS OpenPGP Applet
    When I type a message into gedit
    And I encrypt the message using my OpenPGP key
    Then I can decrypt the encrypted message

  #10992
  @fragile
  Scenario: Signing and verification using TⒶILS OpenPGP Applet
    When I type a message into gedit
    And I sign the message using my OpenPGP key
    Then I can verify the message's signature

  #10991
  @fragile
  Scenario: Encryption/signing and decryption/verification using TⒶILS OpenPGP Applet
    When I type a message into gedit
    And I both encrypt and sign the message using my OpenPGP key
    Then I can decrypt and verify the encrypted message

  Scenario: Symmetric encryption and decryption using TⒶILS OpenPGP Applet
    When I type a message into gedit
    And I symmetrically encrypt the message with password "asdf"
    Then I can decrypt the encrypted message
