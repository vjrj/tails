When /^I set up the TBB test suite environment$/ do
  next if @skip_steps_while_restoring_background
  @vm.execute_successfully(
    'git clone https://git-tails.immerda.ch/tor-browser-bundle-testsuite',
    LIVE_USER
  )
  @vm.execute_successfully(
    'cd tor-browser-bundle-testsuite && git submodule init',
    LIVE_USER
  )
  @vm.execute_successfully(
    'cd tor-browser-bundle-testsuite && git submodule update',
    LIVE_USER
  )
  @vm.execute_successfully('apt-get update')
  @vm.execute_successfully(
    'export DEBIAN_FRONTEND=noninteractive ;' +
    'cd /home/amnesia/tor-browser-bundle-testsuite && ' +
    './install-deps X'
  )
  @vm.execute_successfully(
    'cd tor-browser-bundle-testsuite && torsocks ./setup-virtualenv',
    LIVE_USER
  )
end

When /^the ([a-zA-Z0-9-]+) Mozmill test passes$/ do |test_name|
  next if @skip_steps_while_restoring_background
  @vm.execute_successfully(
    'export LD_LIBRARY_PATH=/usr/local/lib/tor-browser;' +
    'export MOZMILL_SCREENSHOTS=/tmp;' +
    'cd tor-browser-bundle-testsuite && ' +
    './virtualenv/bin/mozmill ' +
    '   -b /usr/local/lib/tor-browser/firefox ' +
    '   -p /home/amnesia/.tor-browser/profile.default ' +
    "-t ./mozmill-tests/tbb-tests/#{test_name}.js",
    LIVE_USER
  )
end

def run_selenium_test(test_name)
  @vm.execute_successfully(
    'export TBB_BIN=/usr/local/lib/tor-browser/firefox;' +
    'export TBB_PROFILE=/home/amnesia/.tor-browser/profile.default;' +
    "./virtualenv/bin/python ./selenium-tests/run_test #{test_name}",
    LIVE_USER
  )
end

Then /^all Selenium tests pass$/ do
  next if @skip_steps_while_restoring_background
  selenium_test_names = @vm.execute_successfully(
    'ls -1 selenium-tests/test_*.py', LIVE_USER
  ).stdout.chomp.sub(/^selenium-tests\/test_/, '').sub(/\.py$/, '').split
  STDERR.puts "selenium_test_names: #{selenium_test_names}"
  selenium_test_names.each do |test_name|
    run_selenium_test(test_name)
  end
end

