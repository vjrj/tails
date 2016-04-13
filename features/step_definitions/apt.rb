require 'uri'

def apt_each_source(*sources)
  if sources.empty?
    sources = ['/etc/apt/sources.list', '/etc/apt/sources.list.d/*']
  end
  $vm.file_content(sources.join(' ')).chomp.each_line do |line|
    split = line.split
    next if line.empty?
    scheme = split[0]
    next unless ['deb', 'deb-src'].include?(scheme)
    host = URI(split[1]).host
    suite = split[2]
    components = split[3, split.size]
    yield(scheme, host, suite, components)
  end
end

Given /^the only hosts in APT sources are "([^"]*)"$/ do |hosts_str|
  hosts = hosts_str.split(',')
  apt_each_source do |_, host, _, _|
    assert(hosts.include?(host), "Bad APT source host '#{host}'")
  end
end

Then /^the expected Tails APT suite is used$/ do
  changelog_dist = cmd_helper('dpkg-parsechangelog -S Distribution').chomp
  if changelog_dist == 'UNRELEASED'
    puts "The last entry in debian/changelog is UNRELEASED so this " +
         "step is passed automatically"
    next
  end
  expected_dist = cmd_helper('dpkg-parsechangelog -S Version').chomp
  nr_sources = 0
  apt_each_source('/etc/apt/sources.list.d/tails.list') do |_, host, dist, _|
    assert_equal('deb.tails.boum.org', host, "Unexpected APT source host")
    assert_equal(expected_dist, dist, "Unexpected APT source suite")
    nr_sources += 1
  end
  assert_equal(1, nr_sources, "Unexpected number of Tails APT sources")
end

When /^I update APT using apt$/ do
  Timeout::timeout(30*60) do
    $vm.execute_successfully("echo #{@sudo_password} | " +
                             "sudo -S apt update", :user => LIVE_USER)
  end
end

Then /^I should be able to install a package using apt$/ do
  package = "cowsay"
  Timeout::timeout(120) do
    $vm.execute_successfully("echo #{@sudo_password} | " +
                             "sudo -S apt install #{package}",
                             :user => LIVE_USER)
  end
  step "package \"#{package}\" is installed"
end

When /^I update APT using Synaptic$/ do
  @screen.click('SynapticReloadButton.png')
  @screen.wait('SynapticReloadPrompt.png', 20)
  @screen.waitVanish('SynapticReloadPrompt.png', 30*60)
end

Then /^I should be able to install a package using Synaptic$/ do
  package = "cowsay"
  try_for(60) do
    @screen.wait_and_click('SynapticSearchButton.png', 10)
    @screen.wait_and_click('SynapticSearchWindow.png', 10)
  end
  @screen.type(package + Sikuli::Key.ENTER)
  @screen.wait_and_double_click('SynapticCowsaySearchResult.png', 20)
  @screen.wait_and_click('SynapticApplyButton.png', 10)
  @screen.wait('SynapticApplyPrompt.png', 60)
  @screen.type(Sikuli::Key.ENTER)
  @screen.wait('SynapticChangesAppliedPrompt.png', 240)
  step "package \"#{package}\" is installed"
end

When /^I start Synaptic$/ do
  step 'I start "Synaptic" via the GNOME "System" applications menu'
  deal_with_polkit_prompt('PolicyKitAuthPrompt.png', @sudo_password)
  @screen.wait('SynapticReloadButton.png', 30)
end
