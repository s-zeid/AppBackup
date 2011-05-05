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

# App class

from __future__ import with_statement

import os

import propertylist

from util import *

__all__ = ["IOS_APP_STORE_APPS_ROOT", "App"]

IOS_APP_STORE_APPS_ROOT    = u"/var/mobile/Applications"

class AppError(Exception): pass

class App(object):
 """Describes an App Store app.

Attributes:
 bundle:    the bundle ID of the app
 friendly:  the display name of the app
 guid:      the name of the .app folder's parent directory
 name:      the name of the .app folder
 path:      the path to the .app folder's parent directory
 sort_key:  useful for sorting
 useable:   True if the app can be accessed; False otherwise

sort_key is the friendly name, converted to lowercase, with diacritical marks
stripped using strip_latin_diacritics, an underscore, and the bundle name.
Example:  facebook_com.facebook.Facebook

"""
 def __init__(self, path):
  """Loads the app's info.

plist_file is the full path to the app's Info.propertylist.

"""
  self.path = path
  self.guid = os.path.basename(self.path)
  plist_file = ""
  for name in os.listdir(self.path):
   if (os.path.isdir(os.path.realpath(os.path.join(self.path, name))) and
       name.endswith(u".app")):
    self.name = name
    plist_file = os.path.join(self.path, self.name, u"Info.plist")
    break
  if not plist_file: raise AppError("This is not a valid iOS App Store app.")
  if os.path.exists(plist_file):
   pl = propertylist.load(plist_file)
   self.bundle   = pl["CFBundleIdentifier"]
   self.friendly = (pl.get("CFBundleDisplayName", "").strip() or
                    self.name.rsplit(u".app", 1)[0])
   self.sort_key = u"%s_%s" % (strip_latin_diacritics(self.friendly.lower()),
                               self.bundle)
   self.useable  = True
  else:
   self.bundle   = "invalid.appbackup.corrupted"
   self.friendly = self.name.rsplit(u".app", 1)[0]
   self.sort_key = u"%s_%s" % (strip_latin_diacritics(self.friendly.lower()),
                               self.bundle)
   self.useable  = False
 @classmethod
 def find(cls, app=None, mode=None, path=None, bundle=None, guid=None,
          root=IOS_APP_STORE_APPS_ROOT, *args, **kwargs):
  """Returns a new AppBackupApp for the given path, bundle, or GUID.

mode can be one of "path", "bundle", or "guid" and takes the place of the
corresponding keyword arguments if set.  Extra arguments are passed to the
class's constuctor.

"""
  if len([i for i in (path, bundle, guid, mode) if i]) is not 1:
   raise ValueError("Please specify only one of path, bundle, guid, or mode.")
  if mode not in ("path", "bundle", "guid", None):
   raise ValueError(repr(mode) + " is not a valid mode.")
  if mode:
   if not app: raise ValueError("Please specify an app to find.")
   if mode == "path":     path = app
   elif mode == "bundle": bundle = app
   elif mode == "guid":   guid = app
  if path:
   try: cls(path, appbackup=self)
   except: return
  elif bundle:
   for i in os.listdir(root):
    if os.path.isdir(os.path.realpath(os.path.join(root, i))):
     for name in os.listdir(os.path.join(root, i)):
      plist_file = os.path.join(root, i, name, u"Info.plist")
      if name.endswith(".app") and os.path.isfile(os.path.realpath(plist_file)):
       this_bundle = propertylist.load(plist_file).get("CFBundleIdentifier")
       if bundle == this_bundle:
        try: return cls(os.path.join(root, i), *args, **kwargs)
        except AppError: continue
  elif guid:
   for i in os.listdir(root):
    if i == guid and os.path.isdir(os.path.realpath(os.path.join(root, i))):
     try: return cls(os.path.join(root, i), *args, **kwargs)
     except AppError: continue
 @classmethod
 def find_all(cls, root=IOS_APP_STORE_APPS_ROOT, *args, **kwargs):
  """Finds all App Store apps.

Returns a dictionary of instances of this method's class which represent the
apps.  Extra arguments are passed to the class's constructor.

"""
  ret = []
  for i in os.listdir(root):
   if os.path.isdir(os.path.realpath(os.path.join(root, i))):
    try: app = cls(os.path.join(root, i), *args, **kwargs)
    except AppError: continue
    ret += [app]
  return ret
 @classmethod
 def sorted(cls, l, key="sort_key"):
  """Returns a given list of Apps sorted according to key.

key is either a string that tells which App attribute should be used as a sort
key, or a callable that is passed an App and returns a sort key.

"""
  if callable(key): return sorted(l, key=key)
  else: return sorted(l, key=lambda app: getattr(app, key))
