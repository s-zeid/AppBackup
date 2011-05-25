# AppBackup
# An iPhoneOS application that backs up and restores the saved data and
# preferences of App Store apps.
#
# Copyright (C) 2008-2011 Scott Zeid
# http://me.srwz.us/iphone/appbackup
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

usage = """Usage: appbackup [options] command [args]

Backs up and restores saved data and settings from iOS App Store apps.

Options:
 -j / --json     Output should be a JSON object.
 -p / --plist    Output should be an XML property list.

Commands:
 -h / --help     Display this help information and exit.
 list [<app>]    Shows information about one or more App Store apps (all apps
                 if <app> is omitted).
 backup <app>    Back up the specified app's data.
 restore <app>   Restore the specified app's data.
 delete <app>    Delete the specified app's backup.
 ignore <app>    Ignore the specified app.
 unignore <app>  Stop ignoring the specified app.

Arguments for all commands:
 -a / --all      Perform the specified action on all App Store apps (not needed
                 for list).
 -g / --guid     A GUID is given as <app> instead of a bundle ID.
 <app>           The bundle IDs (or GUIDs if -g / --guid is set) for each app
                 you want to work with.
 -v / --verbose  Show more information for each app (implied when <app> is
                 given.)"""

import os
import plistlib
import sys

from string import Template

try:
 import json
except ImportError:
 import simplejson as json

from appbackup import *
from justifiedbool import *
from util import *

def app_info(app, human_readable=False, verbose=True, found_key=True):
 info = dict(friendly=app.friendly, bundle=app.bundle, guid=app.guid,
             useable=app.useable, ignored=app.ignored,
             backup_time=app.backup_time_str)
 if verbose or human_readable:
  info["path"] = app.path
 if found_key:
  info["found"] = True
 if human_readable:
  if not info["backup_time"]: info["backup_time"] = "(not backed up)"
  info["ignored"] = "Yes" if info["ignored"] else "No"
  info["useable"] = "Yes" if info["useable"] else "No"
  tpl = u"""$friendly ($bundle):
    GUID:         $guid
    Ignored:      $ignored
    Backup time:  $backup_time
    Path:         $path
    Useable:      $useable"""
  return Template(tpl).substitute(info)
 else:
  return info

def fmt_result(mode, cmd, success=False, exit_code=0, data=None, **kwargs):
 d = dict(cmd=cmd, success=success, exit_code=exit_code, data=data, **kwargs)
 if mode == "json":
  return json.dumps(d)
 elif mode == "plist":
  return plistlib.writePlistToString(d)
 else:
  raise ValueError("mode must be one of json or plist, not %s." % repr(mode))

def main(argv):
 prog = argv[0]
 if len(argv) < 2:
  safe_print(usage)
  return 2
 opts, cmd, args = parse_argv(argv[1:])
 if "h" in opts or "help" in opts:
  safe_print(usage)
  return 0
 use_json = "j" in opts or "json" in opts
 use_plist = "p" in opts or "plist" in opts
 out_mode = ("json" if use_json else "plist") if use_json or use_plist else ""
 if use_json and use_plist:
  safe_print("Please choose only one or neither of -j / --json or -p /"
             " --plist.")
  return 2
 appbackup = AppBackup(find_apps=False)
 if (cmd == "list" and
     "v" not in args and "verbose" not in args and not len(args[""])):
  # List App Store apps and their backup statuses
  apps = appbackup.sort_apps()
  if out_mode:
   data = [app_info(app, verbose=False, found_key=False) for app in apps]
   print fmt_result(out_mode, cmd, True, data=data)
  else:
   for i in apps:
    info = i.backup_time_str
    if not info:
     if not i.useable: info = "(not useable)"
     else: info = "(not backed up)"
    if i.ignored: info = (info + " (ignored)").lstrip()
    safe_print(u"%s (%s): %s" % (i.friendly, (i.bundle if i.useable else i),
                                 info))
  return 0
 elif cmd == "list" and ("v" in args or "verbose" in args or len(args[""])):
  # Show verbose app info
  use_guid = "g" in args or "guid" in args
  all_apps = not len(args[""]) or "a" in args or "all" in args
  verbose  = "v" in args or "verbose" in args
  apps = args[""]
  success = True
  data = []
  if all_apps:
   # List all apps
   apps = appbackup.sort_apps()
   for app in apps:
    if out_mode: data += [app_info(app, verbose=verbose)]
    else: safe_print(app_info(app, True) + "\n")
  else:
   # List some apps
   search_mode = "guid" if use_guid else "bundle"
   for i in apps:
    app = appbackup.find_app(i, search_mode)
    if app:
     if out_mode: data += [app_info(app, verbose=verbose)]
     else: safe_print(app_info(app, True) + "\n")
    else:
     success = False
     if out_mode: data += [dict(name=i, found=False)]
     else: safe_print("Could not find app %s.\n" % repr(i))
  if out_mode: print fmt_result(out_mode, cmd, success, int(not success),
                                data=data)
  return int(not success)
 elif cmd in ("backup", "restore", "delete", "ignore", "unignore"):
  # Other commands
  use_guid = "g" in args or "guid" in args
  all_apps = "a" in args or "all" in args
  verbose  = "v" in args or "verbose" in args
  apps = args[""]
  if not len(apps) and not all_apps:
   error = "Please specify one or more apps, or set -a / --all."
   if out_mode: print fmt_result(out_mode, cmd, False, 2, data=error)
   else: safe_print(error)
   return 2
  success = True
  exit_code = 0
  errors = []
  data = []
  if all_apps:
   # All apps
   result = getattr(appbackup, cmd + "_all")()
   if result.all: success = True
   else:
    success = False
    exit_code = int(not result.any)
    errors = [u"%s: %s" % (i.friendly, result[i].reason) for i in result
              if not result[i]]
  else:
   # Not all apps
   search_mode = "guid" if use_guid else "bundle"
   for i in apps:
    app = appbackup.find_app(i, search_mode)
    if app:
     try:
      getattr(app, cmd)()
      result = True
     except AppBackupError, error:
      result = JustifiedBool(False, str(error))
    else:
     result = JustifiedBool(False, "Could not find app %s." % repr(i))
    data += [app_info(app, verbose=verbose)]
    if not result:
     success = False
     errors += [u"%s: %s" % (app.friendly if app else i, result.reason)]
   if len(apps) == 1 and not success: exit_code = 1
  errors_str = "\n".join(errors)
  if out_mode: print fmt_result(out_mode, cmd, success, exit_code, errors_str,
                                apps=data)
  elif errors_str: safe_print(errors_str)
  return exit_code
 elif cmd == "starbucks":
  # STARBUCKS!!!!!111!11!!!one!!1!
  starbucks = appbackup.starbucks()
  if out_mode: print fmt_result(out_mode, cmd, True, 0, starbucks)
  else: safe_print(starbucks)
  return 0
 else:
  # Invalid command
  error = "%s is not a valid command." % repr(cmd)
  if out_mode: print fmt_result(out_mode, cmd, False, 2, error)
  else: safe_print(error)
  return 2

def parse_argv(argv):
 opts = {}
 cmd = ""
 args = {"": []}
 for i in argv:
  if i.startswith("--"):
   parts = i.lstrip("-").split("=", 1)
   if len(parts) == 1: parts += [True]
   k, v = parts
   (args if cmd else opts)[k] = v
  elif i.startswith("-"):
   for k in i.lstrip("-"):
    (args if cmd else opts)[k] = True
  else:
   if cmd: args[""] += [i]
   else: cmd = i
 return opts, cmd, args

if __name__ == "__main__":
 try:
  sys.exit(main(sys.argv))
 except KeyboardInterrupt:
  pass
