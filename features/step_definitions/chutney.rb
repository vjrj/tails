def ensure_chutney_is_running
  chutney_src_dir = $config["Chutney"]["src_dir"]
  # Ensure that a fresh chutney instnace is running, and that it will
  # be cleaned upon exit. We only do it once, though, since the same
  # setup can be used throughout the same test suite run.
  if not($chutney_initialized)
    chutney_listen_address = $config["Chutney"]["listen_address"]
    chutney_script = "#{chutney_src_dir}/chutney"
    network_definition = "#{GIT_DIR}/features/chutney/test-network"
    env = { 'CHUTNEY_LISTEN_ADDRESS' => chutney_listen_address }
    chutney_cleanup_hook = Proc.new do
      Dir.chdir(chutney_src_dir) do
        cmd_helper([chutney_script, "stop", network_definition], env)
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
    at_exit do
      chutney_cleanup_hook.call
    end
    $chutney_initialized = true
  end
end

When /^Tails is using a simulated Tor network$/ do
  # At the moment this step essentially assumes that we boot with 'the
  # network is unplugged', run this step, and then 'the network is
  # plugged'. I believe we can make this pretty transparent without
  # the need of a dedicated step by using tags (e.g. @fake_tor or
  # whatever -- possibly we want the opposite, @real_tor,
  # instead).
  #
  # There are two time points where we for a scenario must ensure that
  # the client configuration below is enabled if and only if the
  # scenario is tagged, and that is:
  #
  # 1. During a proper boot, as soon as the remote shell is up in the
  #    'the computer boots Tails' step.
  #
  # 2. When restoring a snapshot, in restore_background().
  #
  # If we do this, it doesn't even matter if a snapshot is made of an
  # untagged scenario (without the conf), and we later restore it with
  # a tagged scenario.
  #
  # Note: We probably have to clear the /var/lib/tor data dir when we
  # switch mode. Possibly there are other such problems that make this
  # abstraction impractical and it's better that we avoid it an go
  # with the more explicit, step-based approach.

  assert(not($vm.execute('service tor status').success?),
         "Running this step when Tor is running is probably not intentional")
  ensure_chutney_is_running
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
  chutney_src_dir = $config["Chutney"]["src_dir"]
  dir_auth_lines = open("#{chutney_src_dir}/net/nodes/035c/torrc") do |f|
    f.grep(/^DirAuthority\s/)
  end
  client_torrc_lines.concat(dir_auth_lines)
  $vm.file_append('/etc/tor/torrc', client_torrc_lines)
  $vm.execute_successfully('sed "s/Sandbox 1/Sandbox 0/" ' +
                           '/etc/NetworkManager/dispatcher.d/10-tor.sh')
end
