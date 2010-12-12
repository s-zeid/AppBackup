# AppBackup
# An iPhoneOS application that backs up and restores the saved data and
# preferences of App Store apps.
#
# Copyright (C) 2008-2010 Scott Wallace
# http://pages.srwz.us/iphone/appbackup
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
#
# Loosely based on Dave Arter's (dave@minus-zero.org) sample code from the
# iPhone/Python package.

# NB:  This file is not compiled into optimized Python bytecode anymore.

from __future__ import with_statement # Cydia's Python is 2.5

import atexit
import os
import sys
import time
import traceback

if os.path.exists("/var/mobile/Library/AppBackup") and os.path.exists("/var/mobile/Library/AppBackup/This has been moved") == False:
 libroot = "/var/mobile/Library/AppBackup"
else:
 libroot = "/var/mobile/Library/Preferences/AppBackup"
__starttime__ = time.time()
#__debuglog__ = open(libroot + "/debug.log", "w", 0)
#sys.stdout = __debuglog__
#sys.stderr = __debuglog__
sys.stderr = sys.stdout

try:
 # import some more Python modules we'll use (I imported some a few lines above)
 import ctypes
 import tarfile
 import threading # standard library
 sys.stdout.write("AppBackup[%#.3f]: And now for something completely different.\n" % round(time.time() - __starttime__, 3))
 import objc # PyObjC; this is a dependency of the AppBackup package
 from _uicaboodle import UIApplicationMain
 # import some objc constants
 from objc import YES, NO, NULL
 
 # set working directory to AppBackup.app's location
 os.chdir(os.path.dirname(sys.argv[0]))
 
 # a class to contain global variables
 class shared: pass
 
 # load Latin diacritics for sorting purposes; goes into shared.latin_diacritics
 execfile("include/latin_diacritics.py")
 
 sys.stdout.write("AppBackup[%#.3f]: Iii-t'sss...\n" % round(time.time() - __starttime__, 3))
 
 # load UIKit
 objc.loadBundle("UIKit", globals(), "/System/Library/Frameworks/UIKit.framework")
 
 # load MobileSubstrate
 #if os.path.isfile("/usr/lib/libsubstrate.dylib"):
 # mobileSubstrateDylib = ctypes.cdll.LoadLibrary("/usr/lib/libsubstrate.dylib")
 # mobileSubstrateDylib._MSInitialize()
 #elif os.path.isfile("/Library/MobileSubstrate/MobileSubstrate.dylib"):
 # mobileSubstrateDylib = ctypes.cdll.LoadLibrary("/Library/MobileSubstrate/MobileSubstrate.dylib")
 # mobileSubstrateDylib.MSInitialize()
 
 # other globals are defined in include/globals.py
 # Much stuff has moved around in 1.0.5.  If you can't find what you're looking
 # for here, start with the include/globals.py file.  Stuff related to the main
 # window has been moved to the include/MainWindow.py file.
 execfile("include/globals.py")
 
 # load other classes
 execfile("include/AboutBox.py")
 execfile("include/BackupAll.py")
 execfile("include/BackupOne.py")
 execfile("include/LibraryDirectoryMoved.py")
 execfile("include/MainWindow.py")
 
 # initialize a bunch of variables used in various parts of the app
 shared.script = sys.argv[0]
 shared.info = FoundationPlist.read("Info.plist")
 shared.name = shared.info["CFBundleDisplayName"]
 shared.version = shared.info["CFBundleVersion"]
 sys.stdout.write("AppBackup[%#.3f]: %s version %s\n" % (round(time.time() - __starttime__, 3), shared.name, shared.version))
 log("Started at %#.3f" % round(__starttime__, 3))
 shared.apps_probed = False
 shared.about_title = string("about_title") % shared.name
 shared.plural_last = string("plural_last_letter")
 # Credits are English only for now
 with open("%s/about.txt" % os.path.dirname(shared.script)) as textfo:
  shared.about_text = unicode(textfo.read(), encoding="utf_8_sig")
 shared.web_site = "http://pages.srwz.us/iphone/appbackup"
 shared.libroot = libroot
 shared.backups_moved = False
 shared.tarballs = os.path.join(shared.libroot, "tarballs")
 shared.backuptimesfile = os.path.join(shared.libroot, "backuptimes.plist")
 shared.ignorefile = os.path.join(shared.libroot, "ignore.txt")
 if os.path.exists(shared.libroot) != True:
  os.mkdir(shared.libroot)
 if os.path.exists(shared.tarballs) != True:
  os.mkdir(shared.tarballs)
 if os.path.exists(shared.backuptimesfile) != True:
  save_backuptimes_plist(True)
 if os.path.exists(shared.ignorefile) != True:
  save_ignore_list(True)
 
 # and let's start 'er up!
 UIApplicationMain(sys.argv, MainWindow)
except:
 sys.stdout.write("AppBackup: " + traceback.format_exc() + "\n")
 sys.stdout.write("AppBackup: Exiting...\n")
 sys.stdin.close()
 sys.stdout.flush()
 sys.stderr.flush()
 sys.stdout.close()
 sys.stderr.close()
 atexit._run_exitfuncs()
 os._exit(127)
