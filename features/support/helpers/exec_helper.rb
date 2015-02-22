require 'json'
require 'socket'

class VMCommand

  attr_reader :cmd, :returncode, :stdout, :stderr

  def initialize(vm, cmd, options = {})
    @cmd = cmd
    @returncode, @stdout, @stderr = VMCommand.execute(vm, cmd, options)
  end

  def VMCommand.wait_until_remote_shell_is_up(vm, timeout = 30)
    try_for(30, :msg => "Remote shell seems to be down") do
      Timeout::timeout(3) do
        VMCommand.execute(vm, "echo 'hello?'")
      end
    end
  end

  # The parameter `cmd` cannot contain newlines. Separate multiple
  # commands using ";" instead.
  # If `:spawn` is false the server will block until it has finished
  # executing `cmd`. If it's true the server won't block, and the
  # response will always be [0, "", ""] (only used as an
  # ACK). execute() will always block until a response is received,
  # though. Spawning is useful when starting processes in the
  # background (or running scripts that does the same) like the
  # vidalia-wrapper, or any application we want to interact with.
  def VMCommand.execute(vm, cmd, options = {})
    options[:user] ||= "root"
    options[:spawn] ||= false
    type = options[:spawn] ? "spawn" : "call"
    socket = TCPSocket.new("127.0.0.1", vm.get_remote_shell_port)
    STDERR.puts "#{type}ing as #{options[:user]}: #{cmd}" if $config["DEBUG"]
    begin
      socket.puts(JSON.dump([type, options[:user], cmd]))
      s = socket.readline(sep = "\0").chomp("\0")
    ensure
      socket.close
    end
    STDERR.puts "#{type} returned: #{s}" if $config["DEBUG"]
    begin
      return JSON.load(s)
    rescue JSON::ParserError
      # The server often returns something unparsable for the very
      # first execute() command issued after a VM start/restore
      # (generally from wait_until_remote_shell_is_up()) presumably
      # because the TCP -> serial link isn't properly setup yet. All
      # will be well after that initial hickup, so we just retry.
      return VMCommand.execute(vm, cmd, options)
    end
  end

  def success?
    return @returncode == 0
  end

  def to_s
    "Return status: #{@returncode}\n" +
    "STDOUT:\n" +
    @stdout +
    "STDERR:\n" +
    @stderr
  end

end
