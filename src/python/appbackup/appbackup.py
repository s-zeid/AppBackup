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

# AppBackup public library

"""A library to back up and restore the saved data of iOS App Store apps."""

from __future__ import with_statement

import functools
import os
import stat
import sys
import tarfile
import time
import UserDict

import propertylist

from app import *
from justifiedbool import JustifiedBool
from util import *

__all__ = ["AppBackup", "AppBackupApp", "AppBackupError"]

APPBACKUP_CONFIG_DIRECTORY = u"/var/mobile/Library/Preferences/AppBackup"

class AppBackup(object):
 """The main class of the AppBackup library."""
 def __init__(self, find_apps=True, config_dir=None, apps_root=None):
  if config_dir == None:
   config_dir = APPBACKUP_CONFIG_DIRECTORY
   self._migrate_old_config_dir()
  if apps_root == None: apps_root = IOS_APP_STORE_APPS_ROOT
  dir_mask = stat.S_IRWXU|stat.S_IRGRP|stat.S_IXGRP|stat.S_IROTH|stat.S_IXOTH
  self.config_dir = config_dir
  self._tarballs_dir = os.path.join(config_dir, "tarballs")
  self._backuptimes_plist = os.path.join(config_dir, "backuptimes.plist")
  self._ignore_txt = os.path.join(config_dir, "ignore.txt")
  if not os.path.isdir(os.path.realpath(self.config_dir)):
   os.mkdir(self.config_dir, dir_mask)
  if not os.path.isdir(os.path.realpath(self._tarballs_dir)):
   os.mkdir(self._tarballs_dir, dir_mask)
  self._backup_times = _BackupTimes(self)
  self._ignore_list = _IgnoreList(self)
  self.apps = []
  self.find_app = functools.partial(AppBackupApp.find, appbackup=self)
  if find_apps: self.find_apps()
  else: self._update_backup_info()
 def _do_on_all(self, action):
  # Performs the specified action on all apps.
  self.find_apps()
  results = {}
  if action in ("backup", "delete", "ignore", "restore", "unignore"):
   for app in self.apps:
    if not app.ignored or "ignore" in action:
     try:
      getattr(app, action)(quick=True)
      results[app] = True
     except AppBackupError, error:
      results[app] = JustifiedBool(False, str(error))
   self._update_backup_info()
   return AllAppsResult(action, results)
  else:
   raise AppBackupError("%s is not a valid action." % repr(action))
 def _migrate_old_config_dir(self):
  if (os.path.isdir(os.path.realpath(u"/var/mobile/Library/AppBackup")) and 
      not os.path.exists(u"/var/mobile/Library/AppBackup/This has been moved")):
   if os.path.exists(APPBACKUP_CONFIG_DIRECTORY):
    os.rename(APPBACKUP_CONFIG_DIRECTORY, APPBACKUP_CONFIG_DIRECTORY + ".old")
   os.rename(u"/var/mobile/Library/AppBackup", APPBACKUP_CONFIG_DIRECTORY)
   os.mkdir(u"/var/mobile/Library/AppBackup")
   with open(u"/var/mobile/Library/AppBackup/This has been moved", "w") as f:
    f.write((u"This folder has been moved to %s since AppBackup version 1.0.7."
              % APPBACKUP_CONFIG_DIRECTORY).encode("utf8"))
 def _update_backup_info(self):
  # Updates the any/all_backed_up and any_corrupted attributes.
  self.all_backed_up = bool(len(self.apps))
  self.any_backed_up = self.any_corrupted = False
  for app in self.apps:
   if app.useable:
    if app.bundle in self._backup_times and app.bundle not in self._ignore_list:
     self.any_backed_up = True
    else:
     self.all_backed_up = False
   else:
    self.any_corrupted = True
 def backup_all(self):
  """Backs up all apps' saved data."""
  return self._do_on_all("backup")
 def delete_all(self):
  """Deletes all apps' backups."""
  return self._do_on_all("delete")
 # find_app is a functools.partial defined in AppBackup.__init__
 def find_apps(self, force=False):
  """Initializes self.apps if it doesn't already exist."""
  if force or not hasattr(self, "apps") or not len(self.apps):
   self.apps = AppBackupApp.find_all(appbackup=self)
   self._update_backup_info()
 def ignore_all(self):
  """Tells AppBackup to ignore this app."""
  return self._do_on_all("ignore")
 def restore_all(self):
  """Restores all apps' saved data."""
  return self._do_on_all("restore")
 def sort_apps(self, key="sort_key"):
  """Returns a list of apps sorted by key.

See App.sorted for information about key.

"""
  self.find_apps()
  return AppBackupApp.sorted(self.apps, key)
 def starbucks(self):
  """STARBUCKS!!!!!111!11!!!one!!1!"""
  return u"STARBUCKS!!!!!111!11!!!one!!1!"
 def unignore_all(self):
  """Tells AppBackup to quit ignoring all apps."""
  return self._do_on_all("unignore")

class AppBackupApp(App):
 """Describes an App Store app, along with AppBackup-specific properties.

Attributes (in addition to those defined in the App class):
 appbackup:        the AppBackup instance passed to the constructor
 backup_time:      the last time the app was backed up, as a struct_time
 backup_time_str:  backup_time as a string in ISO 8601 format
 backup_time_unix: backup_time as a Unix timestamp
 ignore:           True if the user wants to ignore this app; False otherwise
 tarpath:          the full path to the .tar.gz backup of the app's data

"""
 def __init__(self, path, appbackup):
  """Loads the app's info.

path is the path to the .app folder's parent directory.
appbackup is an AppBackup instance.

"""
  super(AppBackupApp, self).__init__(path)
  self.appbackup = appbackup
  if self.useable:
   self.tarpath = os.path.join(appbackup._tarballs_dir, self.bundle + ".tar.gz")
   self.ignored = self.bundle in appbackup._ignore_list
   # self._backup_time
   if self.bundle in appbackup._backup_times:
    self._backup_time = appbackup._backup_times[self.bundle]
   elif os.path.isfile(os.path.realpath(self.tarpath)):
    try:
     self._backup_time = time.localtime(float(os.stat(self.tarpath).st_mtime))
    except EnvironmentError: self._backup_time = time.localtime(0)
    appbackup._backup_times.update(self)
   else:
    self._backup_time = None
    appbackup._backup_times.remove(self)
  else:
   self.tarpath = ""
   self.ignored = False
   self._backup_time = None
 @property
 def backup_time(self):
  return self._backup_time
 @property
 def backup_time_str(self):
  return self.format_backup_time()
 @property
 def backup_time_unix(self):
  return float(time.mktime(self.backup_time)) if self.backup_time else 0.0
 def backup(self, quick=False):
  """Backs up this app's saved data."""
  if self.ignored: raise AppBackupError("This app is being ignored.")
  if not self.useable: raise AppBackupError("This app is not useable.")
  if not os.path.exists(self.tarpath):
   f = open(self.tarpath, "w")
   f.close()
  tar = tarfile.open(self.tarpath.encode("utf8"), "w:gz")
  tar.add(os.path.join(self.path, "Documents").encode("utf8"),
          arcname="Documents")
  tar.add(os.path.join(self.path, "Library").encode("utf8"), arcname="Library")
  tar.close()
  self._backup_time = time.localtime()
  self.appbackup._backup_times.update(self, quick)
 def delete(self, quick=False):
  """Deletes this app's BACKUP."""
  if self.ignored: raise AppBackupError("This app is being ignored.")
  if not self.useable: raise AppBackupError("This app is not useable.")
  if os.path.exists(self.tarpath):
   os.remove(self.tarpath)
   self._backup_time = None
   self.appbackup._backup_times.remove(self, quick)
 def format_backup_time(self, fmt="%Y-%m-%d %H:%M:%S"):
  """Formats the backup time, in ISO 8601 format by default."""
  return time.strftime(fmt, self.backup_time) if self.backup_time else ""
 def ignore(self, quick=False):
  """Tells AppBackup to ignore this app."""
  self.appbackup._ignore_list.add(self, quick)
  self.ignored = True
 def restore(self, quick=False):
  """Restores this app's saved data.

Note: The quick argument doesn't currently do anything in this method; it only
exists for compatibility with the other action methods in this class.

"""
  if self.ignored: raise AppBackupError("This app is being ignored.")
  if not self.useable: raise AppBackupError("This app is not useable.")
  if os.path.exists(self.tarpath):
   tar = tarfile.open(self.tarpath.encode("utf8"))
   tar.extractall(self.path.encode("utf8"))
   tar.close()
 def unignore(self, quick=False):
  """Tells AppBackup to quit ignoring this app."""
  self.appbackup._ignore_list.remove(self, quick)
  self.ignored = False

class AppBackupError(Exception):
 def __init__(self, message=None):
  self.message = message or "Unknown error."
 def __repr__(self):
  return "AppBackupError(%s)" % self.message
 def __str__(self):
  return self.message
 def __unicode__(self):
  return to_unicode(self.message)

class AllAppsResult(UserDict.DictMixin):
 def __init__(self, action, results):
  self.__all = True
  self.__any = False
  for app in results:
   if results[app]:
    self.__any = True
   else:
    self.__all = False
  self.__action = action
  self.__results = results
 @property
 def action(self):
  return self.__action
 @property
 def all(self):
  return self.__all
 @property
 def any(self):
  return self.__any
 @property
 def bool(self):
  return self.all
 def __int__(self):
  return int(self.__bool)
 def __nonzero__(self):
  return self.__bool
 def __getitem__(self, item):
  return self.__results[item]
 def keys(self):
  return self.__results.keys()
 def __repr__(self):
  return "<AllAppsResult %s for action %s>" % (repr(self.__bool),
                                               repr(self.action))

class _BackupTimes(object):
 def __init__(self, appbackup):
  self.appbackup = appbackup
  if os.path.isfile(os.path.realpath(self.filename)):
   try:
    self.data = propertylist.load(self.filename)
   except propertylist.PropertyListError:
    self.data = {}
    self.save()
  else:
   self.data = {}
   self.save()
 @property
 def filename(self):
  return self.appbackup._backuptimes_plist
 def __contains__(self, item):
  return item in self.data
 def __getitem__(self, item):
  return time.localtime(float(self.data[item]))
 def get(self, item):
  return self.__getitem__(item)
 def remove(self, app, quick=False):
  if app.bundle in self.data: del self.data[app.bundle]
  self.save()
  if not quick: self.appbackup._update_backup_info()
 def save(self):
  propertylist.save(self.data, self.filename)
 def update(self, app, quick=False):
  self.data[app.bundle] = str(app.backup_time_unix)
  self.save()
  if not quick: self.appbackup._update_backup_info()

class _IgnoreList(object):
 def __init__(self, appbackup):
  self.appbackup = appbackup
  if os.path.isfile(os.path.realpath(self.filename)):
   with open(self.filename) as f: self.data = f.read().splitlines()
  else:
   self.data = []
   self.save()
 @property
 def filename(self):
  return self.appbackup._ignore_txt
 def __contains__(self, item):
  return item in self.data
 def __getitem__(self, item):
  return item in self.data
 def get(self, item):
  return self.__getitem__(item)
 def add(self, app, quick=False):
  if app.bundle not in self.data:
   self.data.append(app.bundle)
   self.data.sort()
   self.save()
  if not quick: self.appbackup._update_backup_info()
 def remove(self, app, quick=False):
  if app.bundle in self.data:
   self.data.remove(app.bundle)
   self.save()
  if not quick: self.appbackup._update_backup_info()
 def save(self):
  with open(self.filename, "w") as f: f.write("\n".join(self.data))
