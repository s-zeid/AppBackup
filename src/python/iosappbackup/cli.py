# AppBackup
# An iOS application that backs up and restores the saved data and
# preferences of App Store apps.
#
# Copyright (C) 2008-2015 Scott Zeid
# https://s.zeid.me/projects/appbackup/
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# 
# Except as contained in this notice, the name(s) of the above copyright holders
# shall not be used in advertising or otherwise to promote the sale, use or
# other dealings in this Software without prior written authorization.

# Command-line interface

"""A command-line interface to AppBackup."""

import argparse
import errno
import os
import signal
import socket
import sys

from iosapplist.cli import CLI, Command, ShellCommand, output
from iosapplist.container import ContainerRoot

from appbackup import *
from justifiedbool import *
from util import *
from . import __version__ as pkg_version


__all__ = ["CLI", "Command", "main"]


def main(argv=sys.argv):
 return CLI().start(argv[1:])


class CLI(CLI):
 default_command = None
 program = "iosappbackup"
 version = pkg_version
 description = "Backs up and restores the saved data and settings of" \
               " installed iOS App Store apps."
 
 app_class  = AppBackupApp
 app_root   = None
 config_dir = None
 
 @property
 def app_list(self):
  return self.appbackup.apps
 
 __appbackup = None
 @property
 def appbackup(self):
  if not self.__appbackup:
   root = ContainerRoot(self.app_root or "/var/mobile")
   default_config_dir = (root.path, "..", "Library", "Preferences", "AppBackup")
   config_dir = self.config_dir or os.path.join(*default_config_dir)
   config_dir = os.path.normpath(config_dir)
   self.__appbackup = AppBackup(find_apps=False, config_dir=config_dir, apps_root=root)
   self.app_root = self.__appbackup.apps.root.path
  return self.__appbackup


class ShellCommand(ShellCommand):
 def add_args(self, p, cli):
  parse_function = super(ShellCommand, self).add_args(p, cli)
  p.add_argument("--config-dir", "-c", default="", metavar='<path>',
                 help='The path to the AppBackup configuration directory'
                      ' (defaults to "<--root>/'
                      '../Library/Preferences/AppBackup").')
  return parse_function
 def main(self, cli):
  output_generator = super(ShellCommand, self).main(cli)
  if cli.config_dir is None:
   cli.config_dir = self.options.config_dir
  return output_generator

CLI.commands.register(ShellCommand)


from iosapplist.cli.commands.python_repl import PythonReplCommand

class PythonReplCommand(PythonReplCommand):
 def main(self, cli):
  output_generator = super(PythonReplCommand, self).main(cli)
  preamble  = "%sappbackup = iosappbackup.AppBackup(find_apps=False)\n"
  preamble %= (self.ps1)  #, repr(cli.app_list.root.input))
  self.preamble += preamble
  return output_generator

CLI.commands.register(PythonReplCommand)


class AppBackupCommands(Command):
 """Performs an action on one or more apps."""
 
 names = ["backup", "restore", "delete", "ignore", "unignore"]
 names_are_aliases = False
 sort_group = 1
 usage = "[-h] [-a] [<bundle-id-or-uuid> [...]]"
 
 @classmethod
 def description(self, name):
  human = dict([(i, i.title() + "s") for i in self.names])
  human["backup"] = "Backs up"
  human["unignore"] = "Un-ignores"
  if name not in ("ignore", "unignore"):
   return "%s the data of one or more apps." % human[name]
  else:
   return "%s one or more apps." % human[name]
 
 def add_args(self, p, cli):
  p.add_argument("-a", "--all", action="store_true",
                 help="Perform the action on all apps.")
  return p.parse_known_args
 
 def main(self, cli):
  action = self.argv[0]
  apps = self.extra
  if not len(apps) and not self.options.all:
   yield output.error("Please specify one or more apps, or use -a / --all.")
   raise StopIteration(2)
  
  if not cli.appbackup.apps:
   cli.appbackup.apps.find_all()
  
  return_code = 127
  success = False
  if self.options.all:
   # All apps
   result = getattr(cli.appbackup, action + "_all")()
   if result.all:
    success = True
    return_code = 0
   else:
    success = False
    return_code = int(not result.any)
   for app, status in result:
    if not status and status.reason != "ignored":
     yield output.error(u"%s: %s" % (app.friendly, status.reason))
    if self.is_robot:
     yield output.normal(dict(app))
  else:
   # Not all apps
   success = True
   for i in apps:
    app = cli.appbackup.apps.get(i, None)
    if app:
     try:
      getattr(app, action)()
      result = True
     except AppBackupError, error:
      result = JustifiedBool(False, str(error))
    else:
     result = JustifiedBool(False, "Could not find app %s." % repr(i))
    if self.is_robot:
     yield output.normal(dict(app))
    if not result:
     success = False
     yield output.error(u"%s: %s" % (app.friendly if app else i, result.reason))
   return_code = 0 if success else (1 if len(apps) == 1 else 0)
  raise StopIteration(return_code)

CLI.commands.register(AppBackupCommands)


class ShellServerCommand(Command):
 """Make the shell available over TCP.

The server will always bind to localhost (127.0.0.1, or ::1 if -6 is used).

Only one client may connect to the server at a time.

Tracebacks from commands executed by clients will be sent to the client
normally as well as sent to (local) standard error.

"""
 names = ["shell-server"]
 show_in_help = False
 usage = "[options [...]] [shell-options [...]]"

 output_format = ""
 
 def add_args(self, p, cli):
  p.add_argument("--port", type=int, default=14121,
                 help="The TCP port to which to bind (defaults to 14121).")
  group = p.add_mutually_exclusive_group()
  group.add_argument("-4", dest="ip_version", action="store_const", const=4,
                     help="Use IPv4 (the default).")
  group.add_argument("-6", dest="ip_version", action="store_const", const=6,
                     help="Use IPv6.")
  p.set_defaults(ip_version=4)
  return p.parse_known_args
 
 def main(self, cli):
  host = "::1" if self.options.ip_version == 6 else "127.0.0.1"
  port = self.options.port
  
  r = 127
  x = None
  af = socket.AF_INET6 if self.options.ip_version == 6 else socket.AF_INET
  s = socket.socket(af, socket.SOCK_STREAM)
  s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
  s.settimeout(None)
  s.bind((host, port))
  try:
   while True:
    r = None
    x = None
    conn = None
    addr_str = None
    try:
     s.listen(0)
     conn, addr = s.accept()
     if self.options.ip_version == 6:
      addr_str = "[%s]:%d" % addr[:2]
     else:
      addr_str = "%s:%d" % addr
     yield output.error("received connection from %s" % addr_str)
     shell = cli.commands["shell"](cli)
     shell.stdin = conn.makefile("rb", 0)
     shell.stdout = conn.makefile("wb", 0)
     r = shell.run(["shell", "--tracebacks-to-stderr"] + self.extra)
    except Exception, exc:
     x = exc
     raise
    finally:
     try:
      if conn is not None:
       conn.shutdown(socket.SHUT_RDWR)
       conn.close()
       conn = "closed"
     except IOError, exc:
      if exc.errno == errno.ENOTCONN:
       conn = "closed"
      else:
       if not x:
        x = exc
        raise
     except Exception, exc:
      if not x:
       x = exc
       raise
     finally:
      if conn == "closed":
       if addr_str:
        closed_message = "connection from %s closed" % addr_str
       else:
        closed_message = "connection closed"
       if r is not None:
        closed_message += "; shell returned %s" % str(r)
       yield output.error(closed_message)
  except KeyboardInterrupt:
   pass
  finally:
   try:
    s.shutdown(socket.SHUT_RDWR)
    s.close()
   except IOError, exc:
    if exc.errno != errno.ENOTCONN:
     if not x:
      x = exc
      raise
  raise StopIteration(r if r is not None else 127)
  yield None

CLI.commands.register(ShellServerCommand)


class BadBehaviorCommand(Command):
 """Used by the GUI to test its error handling capabilities."""
 names = ["--bad-behavior"]
 show_in_help = False
 
 actions = ["exit-while-running-command", "report-traceback"]

 def add_args(self, p, cli):
  p.add_argument("action", help="The type of bad behavior to commit.")
  p.formatter_class = argparse.RawDescriptionHelpFormatter
  p.epilog = "actions:\n" + "\n".join(["  " + action for action in self.actions])
 
 def main(self, cli):
  action = self.options.action
  if action not in self.actions:
   yield output.error("%s is not a valid action" % actions)
   yield output.error("Run `%s --help` for a list of valid actions." % self.argv[0])
  
  if action == "exit-while-running-command":
   # the CLI engine catches SystemExit's, so we can't use sys.exit() for this
   os.kill(os.getpid(), signal.SIGTERM)
  elif action == "report-traceback":
   raise RuntimeError("test error plz ignore kthxbai")
  
  raise StopIteration(0)

CLI.commands.register(BadBehaviorCommand)


class StarbucksCommand(Command):
 """STARBUCKS!!!!!111!11!!!one!!1!"""
 names = ["starbucks"]
 add_args = False
 show_in_help = False
 description = "Outputs the name of a shitty coffee chain."
 
 def main(self, cli):
  yield output.normal(AppBackup.starbucks())
  raise StopIteration(0)

CLI.commands.register(StarbucksCommand)


if __name__ == "__main__":
 try:
  sys.exit(main(sys.argv))
 except KeyboardInterrupt:
  pass
