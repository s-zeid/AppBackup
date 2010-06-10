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

# Globals

### CLASSES ###

# a class to work with plists using Foundation (so we can read binary plists)
class plist:
 # read a binary or XML plist and return the resulting dictionary
 @classmethod
 def read(cls, filename):
  return NSDictionary.alloc().initWithContentsOfFile_(filename)
 # write a dictionary to an XML plist
 @classmethod
 def write(cls, dictionary, filename):
  spam = NSDictionary.alloc().initWithDictionary_(dictionary)
  spam.writeToFile_atomically_(filename, NO)

### FUNCTIONS ###

# escape utf8 characters; there's probably a much simpler way of doing this
def escape_utf8(s):
 r = s.encode('utf8', 'replace').__repr__()
 if len(r) >= 2:
  if r[0] == "'" and r[-1] == "'":
   return r[1:-1]
  if r[0] == '"' and r[-1] == '"':
   return r[1:-1]
 return r

# print debugging text
def log(text, newline=True):
 entry = "AB[%#.3f] %s: %s" % (round(time.time() - __starttime__, 3), shared.name, text)
 entry = escape_utf8(entry)
 if newline:
  entry += "\n"
 sys.stdout.write(entry)
 sys.stdout.flush()

# get a localizable string from LANGUAGE.lproj/Localizable.strings
def string(s):
 return unicode(NSBundle.mainBundle().localizedStringForKey_value_table_(s, "", None))

# replace Latin letters with diacritical marks with the same letters without
# diacritics, preserving case
def strip_latin_diacritics(string):
 ret = string
 for letter in shared.latin_diacritics:
  for i in shared.latin_diacritics[letter]:
   ret = ret.replace(i, letter)
 return ret

# pass a given function, positional arguments, and keyword arguments to the
# __thread_meta function defined below in a separate thread and return the
# thread.
def thread(function, args = [], kwargs = {}):
 t = threading.Thread(
  target=__thread_meta,
  args=[function],
  kwargs={"args": args, "kwargs": kwargs}
 )
 t.start()
 return t

# call a given function with positional arguments args and keyword arguments
# kwargs, and print a traceback and interrupt the main thread if something goes
# wrong.  Also sets up an NSAutoreleasePool for the thread.
# AutoreleasePool code found in Obj-C by arekkusu at <http://bit.ly/9V2NwT>.
def __thread_meta(function, args = [], kwargs = {}):
 try:
  autoreleasepool = NSAutoreleasePool.alloc().init();
  function(*args, **kwargs)
  autoreleasepool.release();
 except:
  sys.stdout.write("Exception in thread:\n")
  sys.stdout.write(traceback.format_exc() + "\n")
  sys.stdout.write("Exiting...\n")
  sys.stdin.close()
  sys.stdout.flush()
  sys.stderr.flush()
  sys.stdout.close()
  sys.stderr.close()
  atexit._run_exitfuncs()
  os._exit(127)

# takes a UNIX timestamp and makes it a string formatted according to
# the device's locale and user preferences
def localized_date(d):
 date = time.strftime("%Y-%m-%d %H:%M:%S", d)
 dateformat = NSDateFormatter.alloc().init()
 dateformat.setDateFormat_("yyyy-MM-dd HH:mm:ss")
 date2 = dateformat.dateFromString_(date)
 dateformat2 = NSDateFormatter.alloc().init()
 dateformat2.setDateStyle_(2)
 dateformat2.setTimeStyle_(1)
 return dateformat2.stringFromDate_(date2)

# write the backup times to ~mobile/Library/AppBackup/backuptimes.plist
def save_backuptimes_plist(init=False):
 if init == True:
  thedict = {}
 else:
  thedict = shared.times
 plist.write(thedict, shared.backuptimesfile)

# makes a list where each item is a dict representing a given app
# each dict has the name of a .app folder, a bundle ID (e.g. com.spam.app),
# the path to the .app folder's parent directory, the app's GUID, the
# display name, the possessive form of the display name,  the time of
# the last backup as a string, the text to display in the table that
# tells you when/if it was backed up, and whether the app is useable
# (not corrupted) or not.  It gets the info from the MobileInstallation cache.
#
# The list is sorted by friendly name, then by bundle ID.
def find_apps(callback=None):
 if not os.path.exists("/var/mobile/Library/Caches/com.apple.mobile.installation.plist"):
  log("MobileInstallation cache not found; reverting to old method of finding apps...")
  find_apps_old(callback=callback)
  return
 try:
  mobileInstallationCache = plist.read("/var/mobile/Library/Caches/com.apple.mobile.installation.plist")
 except:
  log("Reading the MobileInstallation cache failed; reverting to old method of finding apps...")
  find_apps_old(callback=callback)
  return
 if "User" not in mobileInstallationCache:
  log("MobileInstallation cache doesn't have a User key; reverting to old method of finding apps...")
  find_apps_old(callback=callback)
  return
 appStoreApps = mobileInstallationCache["User"]
 applist = []; appdict = {}
 shared.all_bak = True; shared.any_bak = False; shared.any_corrupted = False
 if shared.apps_probed == False:
  # Debug text; do not translate
  log("Here are the app bundles I found:")
 for key in appStoreApps:
  i = appStoreApps[key]
  path = "/".join(i["Path"].rstrip("/").split("/")[:-1])
  if os.path.exists(path) and "CFBundleIdentifier" in i and i["CFBundleIdentifier"] != "":
   useable = True
   dotApp = i["Path"].rstrip("/").split("/")[-1]
   dotAppFull = path + "/" + dotApp
   if path.startswith("/private"):
    path = path.split("/private", 1)[1]
   guid = path.split("/")[-1]
   if shared.apps_probed == False:
    # More debug text
    log(unicode(escape_utf8(dotAppFull)))
   if "CFBundleDisplayName" in i:
    friendly = i["CFBundleDisplayName"]
    if friendly == "":
     friendly = dotApp.rsplit(u".app", 1)[0]
   else:
    friendly = dotApp.rsplit(u".app", 1)[0]
   bundle = i["CFBundleIdentifier"]
   sortname = u"%s_%s" % (strip_latin_diacritics(friendly).lower(), bundle)
   if bundle in shared.times:
    baksec = time.localtime(float(shared.times[bundle]))
    bak = localized_date(baksec)
    baktext = string("baktext_yes") % bak
    shared.any_bak = True
   else:
    bak = None
    baktext = string("baktext_no")
    shared.all_bak = False
  else:
   useable = False
   shared.any_corrupted = True
   if "CFBundleDisplayName" in i:
    friendly = i["CFBundleDisplayName"]
    if friendly == "":
     friendly = dotApp.rsplit(u".app", 1)[0]
   else:
    friendly = dotApp.rsplit(u".app", 1)[0]
   if "CFBundleIdentifier" in i:
    bundle = i["CFBundleIdentifier"]
   else:
    bundle = "invalid.appbackup.corrupted"
   sortname = u"%s_%s" % (strip_latin_diacritics(friendly).lower(), bundle)
   bak = None
   baktext = string("app_corrupted_list")
  
  if shared.plural_last != "" and friendly[-1] == shared.plural_last:
   possessive = string("plural_possessive") % friendly
  else:
   possessive = string("singular_possessive") % friendly
  
  applist.append(sortname)
  appdict[sortname] = {
   "key": sortname,
   "name": dotApp,
   "bundle": bundle,
   "path": path,
   "guid": guid,
   "friendly": friendly,
   "possessive": possessive,
   "bak": bak,
   "bak_text": baktext,
   "useable": useable
  }
 log("Found all App Store apps; sorting...")
 applist.sort()
 log("done.  Now for the finishing touches...")
 shared.apps = []
 for i in applist:
  shared.apps.append(appdict[i])
 shared.apps_probed = True
 log("done.  Now, back to our regularly scheduled programming, ")
 log(callback.__repr__() + ".")
 if callback != None:
  callback()

# this backs up or restores a given app
def act_on_app(app, index, action):
 if app["useable"] == False:
  return False
 path = str(app["path"])
 bundle = str(app["bundle"])
 tarpath = str("%s/%s.tar.gz" % (shared.tarballs, bundle))
 logtext = '"' + app["friendly"] + "\" (%s, %s, %s)..." % (bundle, path, tarpath)
 if action == "Backup":  # Internal string; don't translate
  log("Backing up " + escape_utf8(logtext))
  if os.path.exists(tarpath) != True:
   log("Creating archive...")
   f = open(tarpath, "w")
   f.close()
  log("Opening archive...")
  tar = tarfile.open(tarpath, "w:gz")
  log("Archiving path/Documents...")
  tar.add(path+"/Documents", arcname="Documents")
  log("Archiving path/Library...")
  tar.add(path+"/Library", arcname="Library")
  log("Closing tarball...")
  tar.close()
  now = str(time.mktime(time.localtime()))
  log("Finished backup at " + now)
  return now
 if action == "Restore":  # Internal string; don't translate
  log("Restoring " + escape_utf8(logtext))
  if os.path.exists(tarpath) == True:
   log("Opening archive...")
   tar = tarfile.open(tarpath)
   log("Extracting...")
   tar.extractall(path)
   log("Closing archive...")
   tar.close()
   return True
  else:
   log("The file %s does not exist.  Asking Congress for a bailout..." % tarpath)
   return False

def update_backup_time(index = None, backupTime = None, iterate = True, iterateOnly = False):
 if iterateOnly == False:
  if index == None or backupTime == None:
   return False
  bundle = shared.apps[index]["bundle"]
  shared.times[bundle] = backupTime
  save_backuptimes_plist()
  bak = localized_date(time.localtime(float(backupTime)))
  shared.apps[index]["bak"] = bak
  shared.apps[index]["bak_text"] = string("baktext_yes") % bak
 if iterate:
  shared.any_bak = True; shared.all_bak = True
  for i in shared.apps:
   if i["bundle"] not in shared.times:
    shared.all_bak = False

# makes a list where each item is a dict representing a given app
# each dict has the name of a .app folder, a bundle ID (e.g. com.spam.app),
# the path to the .app folder's parent directory, the app's GUID, the
# display name, the possessive form of the display name,  the time of
# the last backup as a string, the text to display in the table that
# tells you when/if it was backed up, and whether the app is useable
# (not corrupted) or not.  It gets its info by manually looking at each App
# Store app's Info.plist file, and has been deprecated by find_apps.  It used
# to be called make_app_dict.
#
# The list is sorted by friendly name, then by bundle ID.
def find_apps_old(callback=None):
 mobile = u"/var/mobile"
 root = mobile+"/Applications"
 applist = []; applist1 = []; appdict = {}; apps = []
 apps1 = os.listdir(root)
 for i in apps1:
  if os.path.isdir(root+"/"+i) == True:
   apps.append(i)
 shared.all_bak = True; shared.any_bak = False; shared.any_corrupted = False
 if shared.apps_probed == False:
  # Debug text; do not translate
  log("Here are the app bundles and Info.plist's I found:")
 for k in apps:
  appdir = root+"/"+k
  for j in os.listdir(appdir):
   if j.endswith(u".app"):
    plistfile = u"%s/%s/Info.plist" % (appdir, j)
    if shared.apps_probed == False:
     # More debug text
     log(u"%s:  %s" % (escape_utf8(j), escape_utf8(plistfile.split(root+"/", 1)[1])))
    if os.path.exists(plistfile) == True:
     pl = plist.read(plistfile)
     bundle = pl["CFBundleIdentifier"]
     if "CFBundleDisplayName" in pl:
      friendly = pl["CFBundleDisplayName"]
      if friendly == "":
       friendly = j.rsplit(u".app", 1)[0]
     else:
      friendly = j.rsplit(u".app", 1)[0]
     sortname = u"%s_%s" % (friendly.lower(), bundle)
     useable = True
     
     if bundle in shared.times:
      baksec = time.localtime(float(shared.times[bundle]))
      bak = localized_date(baksec)
      baktext = string("baktext_yes") % bak
      shared.any_bak = True
     else:
      bak = None
      baktext = string("baktext_no")
      shared.all_bak = False
    else:
     shared.any_corrupted = True
     friendly = j.rsplit(u".app", 1)[0]
     bundle = "invalid.appbackup.corrupted"
     sortname = u"%s_%s" % (friendly, bundle)
     bak = None
     baktext = string("app_corrupted_list")
     useable = False
    
    if shared.plural_last != "" and friendly[-1] == shared.plural_last:
     possessive = string("plural_possessive") % friendly
    else:
     possessive = string("singular_possessive") % friendly
    
    applist1.append(sortname)
    appdict[sortname] = {
     "key": sortname,
     "name": j,
     "bundle": bundle,
     "path": appdir,
     "guid": k,
     "friendly": friendly,
     "possessive": possessive,
     "bak": bak,
     "bak_text": baktext,
     "useable": useable
    }
 log("Found all App Store apps; sorting...")
 # wait for uca_init to finish
 while shared.ucaInitThread.isAlive():
  time.sleep(0.125)
 applist1.sort(key=shared.ucaCollator.sort_key)
 log("done.  Now for the finishing touches...")
 for i in applist1:
  applist.append(appdict[i])
 shared.apps = applist
 shared.apps_probed = True
 log("done.  Now, back to our regularly scheduled programming, ")
 log(callback.__repr__() + ".")
 if callback != None:
  callback()
