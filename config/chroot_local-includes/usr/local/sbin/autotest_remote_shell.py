#!/usr/bin/python

# ATTENTION: Yes, this can be used as a backdoor, but only for an
# adversary with access to you *physical* serial port, which means
# that you are screwed any way.

from subprocess import Popen, PIPE
from sys import argv
from json import dumps, loads
from pwd import getpwnam
from os import setgid, setuid, environ
from glob import glob
import serial

def mk_switch_user_fn(uid, gid):
    def switch_user():
        setgid(gid)
        setuid(uid)
    return switch_user

def run_cmd_as_user(cmd, user):
  pwd_user = getpwnam(user)
  switch_user_fn = mk_switch_user_fn(pwd_user.pw_uid,
                                     pwd_user.pw_gid)
  # We try to create an environment identical to what's expected
  # inside Tails for the user by logging in (via `su`) as the user and
  # extracting the environment.
  pipe = Popen('su -c env ' + user, stdout=PIPE, shell=True)
  env_data = pipe.communicate()[0]
  env = dict((line.split('=', 1) for line in env_data.splitlines()))
  env['DISPLAY'] = ':0.0'
  try:
    env['XAUTHORITY'] = glob("/var/run/gdm3/auth-for-amnesia-*/database")[0]
  except IndexError:
    pass
  cwd = env['HOME']
  return Popen(cmd, stdout=PIPE, stderr=PIPE, shell=True, env=env, cwd=cwd,
               preexec_fn=switch_user_fn)

def main():
  dev = argv[1]
  port = serial.Serial(port = dev, baudrate = 4000000)
  port.open()
  while True:
    try:
      line = port.readline()
    except Exception as e:
      # port must be opened wrong, so we restart everything and pray
      # that it works.
      print str(e)
      port.close()
      return main()
    try:
      cmd_type, user, cmd = loads(line)
    except Exception as e:
      # We had a parse/pack error, so we just send a \0 as an ACK,
      # releasing the client from blocking.
      print str(e)
      port.write("\0")
      continue
    p = run_cmd_as_user(cmd, user)
    if cmd_type == "spawn":
      returncode, stdout, stderr = 0, "", ""
    else:
      stdout, stderr = p.communicate()
      returncode = p.returncode
    port.write(dumps([returncode, stdout, stderr]) + "\0")

if __name__ == "__main__":
  main()
