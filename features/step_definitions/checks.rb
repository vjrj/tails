Then /^the shipped Tails signing key is not outdated$/ do
  # "old" here is w.r.t. the one we fetch from Tails' website
  next if @skip_steps_while_restoring_background
  sig_key_fingerprint = "0D24B36AA9A2A651787876451202821CBE2CD9C1"
  fresh_sig_key = "/tmp/tails-signing.key"
  tmp_keyring = "/tmp/tmp-keyring.gpg"
  key_url = "https://tails.boum.org/tails-signing.key"
  @vm.execute("curl --silent --socks5-hostname localhost:9062 " +
              "#{key_url} -o #{fresh_sig_key}", $live_user)
  @vm.execute("gpg --batch --no-default-keyring --keyring #{tmp_keyring} " +
              "--import #{fresh_sig_key}", $live_user)
  fresh_sig_key_info =
    @vm.execute("gpg --batch --no-default-keyring --keyring #{tmp_keyring} " +
                "--list-key #{sig_key_fingerprint}", $live_user).stdout
  shipped_sig_key_info = @vm.execute("gpg --batch --list-key #{sig_key_fingerprint}",
                                     $live_user).stdout
  assert_equal(fresh_sig_key_info, shipped_sig_key_info,
         "The Tails signing key shipped inside Tails is outdated:\n" +
         "Shipped key:\n" +
         shipped_sig_key_info +
         "Newly fetched key from #{key_url}:\n" +
         fresh_sig_key_info)
end

Then /^the live user has been setup by live\-boot$/ do
  next if @skip_steps_while_restoring_background
  assert(@vm.execute("test -e /var/lib/live/config/user-setup").success?,
         "live-boot failed its user-setup")
  actual_username = @vm.execute(". /etc/live/config/username.conf; " +
                                "echo $LIVE_USERNAME").stdout.chomp
  assert_equal($live_user, actual_username)
end

Then /^the live user is a member of only its own group and "(.*?)"$/ do |groups|
  next if @skip_steps_while_restoring_background
  expected_groups = groups.split(" ") << $live_user
  actual_groups = @vm.execute("groups #{$live_user}").stdout.chomp.sub(/^#{$live_user} : /, "").split(" ")
  unexpected = actual_groups - expected_groups
  missing = expected_groups - actual_groups
  assert_equal(0, unexpected.size,
         "live user in unexpected groups #{unexpected}")
  assert_equal(0, missing.size,
         "live user not in expected groups #{missing}")
end

Then /^the live user owns its home dir and it has normal permissions$/ do
  next if @skip_steps_while_restoring_background
  home = "/home/#{$live_user}"
  assert(@vm.execute("test -d #{home}").success?,
         "The live user's home doesn't exist or is not a directory")
  owner = @vm.execute("stat -c %U:%G #{home}").stdout.chomp
  perms = @vm.execute("stat -c %a #{home}").stdout.chomp
  assert_equal("#{$live_user}:#{$live_user}", owner)
  assert_equal("700", perms)
end

Given /^I wait between (\d+) and (\d+) seconds$/ do |min, max|
  next if @skip_steps_while_restoring_background
  time = rand(max.to_i - min.to_i + 1) + min.to_i
  puts "Slept for #{time} seconds"
  sleep(time)
end

Then /^no unexpected services are listening for network connections$/ do
  next if @skip_steps_while_restoring_background
  netstat_cmd = @vm.execute("netstat -ltupn")
  assert netstat_cmd.success?
  for line in netstat_cmd.stdout.chomp.split("\n") do
    splitted = line.split(/[[:blank:]]+/)
    proto = splitted[0]
    if proto == "tcp"
      proc_index = 6
    elsif proto == "udp"
      proc_index = 5
    else
      next
    end
    laddr, lport = splitted[3].split(":")
    proc = splitted[proc_index].split("/")[1]
    # Services listening on loopback is not a threat
    if /127(\.[[:digit:]]{1,3}){3}/.match(laddr).nil?
      if $services_expected_on_all_ifaces.include? [proc, laddr, lport] or
         $services_expected_on_all_ifaces.include? [proc, laddr, "*"]
        puts "Service '#{proc}' is listening on #{laddr}:#{lport} " +
             "but has an exception"
      else
        raise "Unexpected service '#{proc}' listening on #{laddr}:#{lport}"
      end
    end
  end
end

When /^Tails has booted a 64-bit kernel$/ do
  next if @skip_steps_while_restoring_background
  assert(@vm.execute("uname -r | grep -qs 'amd64$'").success?,
         "Tails has not booted a 64-bit kernel.")
end

Then /^the VirtualBox guest modules are available$/ do
  next if @skip_steps_while_restoring_background
  assert(@vm.execute("modinfo vboxguest").success?,
         "The vboxguest module is not available.")
end

def shared_pdf_dir_on_guest
  "/tmp/shared_pdf_dir"
end

Given /^I setup a filesystem share containing a sample PDF$/ do
  next if @skip_steps_while_restoring_background
  @vm.add_share($misc_files_dir, shared_pdf_dir_on_guest)
end

Then /^MAT can clean some sample PDF file$/ do
  next if @skip_steps_while_restoring_background
  for pdf_on_host in Dir.glob("#{$misc_files_dir}/*.pdf") do
    pdf_name = File.basename(pdf_on_host)
    pdf_on_guest = "/home/#{$live_user}/#{pdf_name}"
    step "I copy \"#{shared_pdf_dir_on_guest}/#{pdf_name}\" to \"#{pdf_on_guest}\" as user \"#{$live_user}\""
    @vm.execute("mat --display '#{pdf_on_guest}'",
                $live_user).stdout
    check_before = @vm.execute("mat --check '#{pdf_on_guest}'",
                               $live_user).stdout
    if check_before.include?("#{pdf_on_guest} is clean")
      STDERR.puts "warning: '#{pdf_on_host}' is already clean so it is a " +
                  "bad candidate for testing MAT"
    end
    @vm.execute("mat '#{pdf_on_guest}'", $live_user)
    check_after = @vm.execute("mat --check '#{pdf_on_guest}'",
                              $live_user).stdout
    assert(check_after.include?("#{pdf_on_guest} is clean"),
           "MAT failed to clean '#{pdf_on_host}'")
  end
end

Then /^AppArmor is enabled$/ do
  assert(@vm.execute("aa-status").success?, "AppArmor is not enabled")
end

Then /^some AppArmor profiles are enforced$/ do
  assert(@vm.execute("aa-status --enforced").stdout.chomp.to_i > 0,
         "No AppArmor profile is enforced")
end
