Given /^I2P is running$/ do
  next if @skip_steps_while_restoring_background
  try_for(30) do
    @vm.execute('service i2p status').success?
  end
end

Given /^the I2P router console is ready$/ do
  next if @skip_steps_while_restoring_background
  try_for(60) do
    @vm.execute('. /usr/local/lib/tails-shell-library/i2p.sh; ' +
                'i2p_router_console_is_ready').success?
  end
end

When /^I start the I2P Browser through the GNOME menu$/ do
  next if @skip_steps_while_restoring_background
  @screen.wait_and_click("GnomeApplicationsMenu.png", 10)
  @screen.wait_and_click("GnomeApplicationsInternet.png", 10)
  @screen.wait_and_click("GnomeApplicationsI2PBrowser.png", 20)
end

Then /^the I2P Browser desktop file is (|not )present$/ do |mode|
  next if @skip_steps_while_restoring_background
  file = '/usr/share/applications/i2p-browser.desktop'
  if mode == ''
    assert(@vm.execute("test -e #{file}").success?)
  elsif mode == 'not '
    assert(@vm.execute("! test -e #{file}").success?)
  else
    raise "Unsupported mode passed: '#{mode}'"
  end
end

Then /^the I2P Browser sudo rules are (enabled|not present)$/ do |mode|
  next if @skip_steps_while_restoring_background
  file = '/etc/sudoers.d/zzz_i2pbrowser'
  if mode == 'enabled'
    assert(@vm.execute("test -e #{file}").success?)
  elsif mode == 'not present'
    assert(@vm.execute("! test -e #{file}").success?)
  else
    raise "Unsupported mode passed: '#{mode}'"
  end
end

Then /^the I2P firewall rules are (enabled|disabled)$/ do |mode|
  next if @skip_steps_while_restoring_background
  i2p_username = 'i2psvc'
  i2p_uid = @vm.execute("getent passwd #{i2p_username} | awk -F ':' '{print $3}'").stdout.chomp
  accept_rules = @vm.execute("iptables -L -n -v | grep -E '^\s+[0-9]+\s+[0-9]+\s+ACCEPT.*owner UID match #{i2p_uid}$'").stdout
  accept_rules_count = accept_rules.lines.count
  if mode == 'enabled'
    assert_equal(13, accept_rules_count)
  elsif mode == 'disabled'
    assert_equal(0, accept_rules_count)
  else
    raise "Unsupported mode passed: '#{mode}'"
  end
end
