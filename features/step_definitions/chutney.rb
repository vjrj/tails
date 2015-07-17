When /^Tails is using a simulated Tor network$/ do
  assert(not($vm.execute('service tor status').success?),
         "Running this step when Tor is running is probably not intentional")

  # Ensure that a fresh chutney instnace is running, and that it will
  # be cleaned upon exit.
  chutney_listen_address = $config["Chutney"]["listen_address"]
  chutney_src_dir = $config["Chutney"]["src_dir"]
  chutney_script = "#{chutney_src_dir}/chutney"
  network_definition = "#{GIT_DIR}/features/chutney/test-network"
  env = { 'CHUTNEY_LISTEN_ADDRESS' => chutney_listen_address }
  chutney_cleanup_hook = Proc.new do
    Dir.chdir(chutney_src_dir) do
      cmd_helper([chutney_script, "stop", network_definition], env)
      FileUtils.rm_r("#{chutney_src_dir}/net")
    end
  end
  Dir.chdir(chutney_src_dir) do
    begin
      cmd_helper([chutney_script, "status", network_definition], env)
    rescue Test::Unit::AssertionFailedError
      # chutney is not running so we're good to set up a fresh
      # instance.
    else
      # We clean up any previous (aborted/crashed) test suite run's
      # chutney instance to ensure that we're running the current
      # defined version of the simulated Tor network.
      chutney_cleanup_hook.call
    end
    cmd_helper([chutney_script, "configure", network_definition], env)
    cmd_helper([chutney_script, "start", network_definition], env)
  end
  # Let's only add this hook once
  if not($chutney_cleanup_hook_added)
    at_exit do
      chutney_cleanup_hook.call
    end
    $chutney_cleanup_hook_added = true
  end

  # Most of these lines are taken from chutney's client template.
  client_torrc_lines = [
    'TestingTorNetwork 1',
    'AssumeReachable 1',
    'PathsNeededToBuildCircuits 0.25',
    'TestingDirAuthVoteExit *',
    'TestingDirAuthVoteHSDir *',
    'V3AuthNIntervalsValid 2',
    'TestingDirAuthVoteGuard *',
    'TestingMinExitFlagThreshold 0',
    'TestingClientDownloadSchedule 0, 5',
    'TestingClientConsensusDownloadSchedule 0, 5',
  ]
  # We run one client in chutney so we easily can grep the generated
  # DirAuthority lines and use them.
  dir_auth_lines = open("#{chutney_src_dir}/net/nodes/035c/torrc") do |f|
    f.grep(/^DirAuthority\s/)
  end
  client_torrc_lines.concat(dir_auth_lines)
  client_torrc_lines.each do |line|
    $vm.file_append('/etc/tor/torrc', line)
  end
end
