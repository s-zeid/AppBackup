# AppBackup
# An iPhoneOS application that backs up and restores the saved data and
# preferences of App Store apps.
#
# Copyright (C) 2008-2010 Scott Wallace
# http://www.scott-wallace.net/iphone/appbackup
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
#
# Loosely based on Dave Arter's (dave@minus-zero.org) sample code from the
# iPhone/Python package.

# NB:  This file is not compiled into optimized Python bytecode anymore.

from __future__ import with_statement # Cydia's Python is 2.5
import atexit, os, sys, time, traceback

if os.path.exists("/var/mobile/Library/AppBackup") and os.path.exists("/var/mobile/Library/AppBackup/This has been moved") == False:
 __libroot__ = "/var/mobile/Library/AppBackup"
else:
 __libroot__ = "/var/mobile/Library/Preferences/AppBackup"
__starttime__ = time.time()
__debuglog__ = open(__libroot__ + "/debug.log", "w", 0)
sys.stdout = __debuglog__
sys.stderr = __debuglog__
try:
 # import some more Python modules we'll use (I imported some a few lines above)
 import ctypes, tarfile, threading # standard library
 sys.stdout.write("[%#.3f] And now for something completely different.\n" % round(time.time() - __starttime__, 3))
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
 
 sys.stdout.write("[%#.3f] Iii-t'sss...\n" % round(time.time() - __starttime__, 3))
 
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
 shared.apps_probed = False
 shared.script = sys.argv[0]
 shared.info = plist.read("Info.plist")
 shared.name = shared.info["CFBundleDisplayName"]
 shared.version = shared.info["CFBundleVersion"]
 sys.stdout.write("[%#.3f] %s version %s\n" % (round(time.time() - __starttime__, 3), shared.name, shared.version))
 log("Started at %#.3f" % round(__starttime__, 3))
 shared.about_title = string("about_title") % shared.name
 shared.plural_last = string("plural_last_letter")
 # Credits are English only for now
 with open("%s/CREDITS.txt" % os.path.dirname(shared.script)) as textfo:
  shared.about_text = unicode(textfo.read(), encoding="utf_8_sig")
 shared.web_site = "http://www.scott-wallace.net/iphone/appbackup"
 shared.libroot = __libroot__
 shared.backups_moved = False
 shared.tarballs = shared.libroot+"/tarballs"
 shared.backuptimesfile = shared.libroot+"/backuptimes.plist"
 if os.path.exists(shared.libroot) != True:
  os.mkdir(shared.libroot)
 if os.path.exists(shared.tarballs) != True:
  os.mkdir(shared.tarballs)
 if os.path.exists(shared.backuptimesfile) != True:
  save_backuptimes_plist(True)
 
 # and let's start 'er up!
 UIApplicationMain(sys.argv, MainWindow)
except:
 sys.stdout.write(traceback.format_exc() + "\n")
 sys.stdout.write("Exiting...\n")
 sys.stdin.close()
 sys.stdout.flush()
 sys.stderr.flush()
 sys.stdout.close()
 sys.stderr.close()
 atexit._run_exitfuncs()
 os._exit(127)
