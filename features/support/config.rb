require 'fileutils'
require "#{Dir.pwd}/features/support/helpers/misc_helpers.rb"

# Dynamic
$tails_iso = ENV['ISO'] || get_newest_iso
$old_tails_iso = ENV['OLD_ISO'] || get_oldest_iso
$tmp_dir = ENV['TEMP_DIR'] || "/tmp/TailsToaster"
$vm_xml_path = ENV['VM_XML_PATH'] || "#{Dir.pwd}/features/domains"
$misc_files_dir = "#{Dir.pwd}/features/misc_files"
$keep_snapshots = !ENV['KEEP_SNAPSHOTS'].nil?
$x_display = ENV['DISPLAY']
$debug = !ENV['DEBUG'].nil?
$time_at_start = Time.now
$live_user = cmd_helper(". config/chroot_local-includes/etc/live/config.d/username.conf; echo ${LIVE_USERNAME}").chomp
$sikuli_retry_findfailed = !ENV['SIKULI_RETRY_FINDFAILED'].nil?

# Static
$configured_keyserver_hostname = 'hkps.pool.sks-keyservers.net'
$services_expected_on_all_ifaces =
  [
   ["cupsd",    "0.0.0.0", "631"],
   ["dhclient", "0.0.0.0", "*"]
  ]
$tor_authorities =
  # List grabbed from Tor's sources, src/or/config.c:~750.
  [
   "128.31.0.39", "86.59.21.38", "194.109.206.212",
   "82.94.251.203", "76.73.17.194", "212.112.245.170",
   "193.23.244.244", "208.83.223.34", "171.25.193.9",
   "154.35.32.5"
  ]
# OpenDNS
$some_dns_server = "208.67.222.222"
