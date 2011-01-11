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
#
# Loosely based on Dave Arter's (dave@minus-zero.org) sample code from the
# iPhone/Python package.

# Code related to backing up or restoring all App Store apps' data

# This is an Objective-C class.  You must do BackupAll.alloc().init() to get a
# new instance.
class BackupAll(UIActionSheet):
 # what to do when you click the "All" button
 def init(self):
  self = super(BackupAll, self).init()
  if self == None: return None
  self.setTitle_(string("all_apps"))
  backup = self.addButtonWithTitle_(string("backup"))
  if shared.any_bak == True:
   text = string("backup_restore_all_apps")
   restore = self.addButtonWithTitle_(string("restore"))
   delete = self.addButtonWithTitle_(string("delete"))
  else:
   text = string("backup_all_apps")
  self.setBodyText_(text)
  self.setDelegate_(self)
  cancel = self.addButtonWithTitle_(string("cancel"))
  self.setCancelButtonIndex_(cancel)
  return self
 
 # what to do when you close the BackupAll prompt
 # (tell the user what we're doing and run onAllAppsDoAction with the action
 # and the modal alert in a separate thread, so that the user actually sees the
 # modal)
 @objc.signature("v@:@i")
 def actionSheet_didDismissWithButtonIndex_(self, malert, index):
  action_localized = malert.buttonTitleAtIndex_(index)
  if action_localized != string("cancel"):
   # We're using a UIModalView so it doesn't show
   # the space where buttons go (we have no buttons)
   modal = UIModalView.alloc().init()
   modal.setTitle_(string("please_wait"))
   if action_localized == string("backup"):
    action = "backup"
   elif action_localized == string("restore"):
    action = "restore"
   elif action_localized == string("delete"):
    action = "delete"
   text = string("all_status_%s_doing" % action)
   modal.setBodyText_(text)
   modal.popupAlertAnimated_(YES)
   actingThread = thread(self.onAllAppsDoAction_withModalView_, [action, modal])
 
 # act on all apps, close the given modal, and tell the user about the results
 def onAllAppsDoAction_withModalView_(self, action, modal):
  text2 = string("all_status_%s_done" % action)
  text3 = string("all_status_%s_failed" % action)
  text4 = string("all_status_%s_corrupted" % action)
  alldonetext = string(action + "_done")
  allpartdonetext = string(action + "_partially_done")
  alldone = True
  failed = []
  corrupted = []
  any_corrupted = False
  position = 0
  for app in shared.apps:
   if app["useable"] == True and app["ignore"] == False:
    if action == "backup":
     ret = act_on_app(app, position, "Backup")
     if ret == False:
      alldone = False
      failed.append(app["friendly"])
     else:
      update_backup_time(position, ret, iterate=False)
      shared.list.reloadData()
    elif action == "restore" and app["bak_time"] != None:
     ret = act_on_app(app, position, "Restore")
     if ret != True:
      alldone = False
      failed.append(app["friendly"])
    elif action == "delete" and app["bak_time"] != None:
     ret = act_on_app(app, position, "Delete")
     if ret != True:
      alldone = False
      failed.append(app["friendly"])
     else:
      update_backup_time(position, None, iterate=False)
      shared.list.reloadData()
   elif app["useable"] == False:
    any_corrupted = True
    corrupted.append(app["friendly"])
    failed.append(app["friendly"] + " (corrupted)")
   position += 1
  if action == "backup" or action == "delete":
   update_backup_time(iterateOnly=True)
   #find_apps()
   shared.list.reloadData()
   time.sleep(1)
  if alldone == True and any_corrupted == False:
   title = alldonetext
   body = text2
  elif alldone == True and any_corrupted == True:
   title = allpartdonetext
   corruptedstring = "\n".join(corrupted)
   body = "%s\n\n%s" % (text4, corruptedstring)
  else:
   title = allpartdonetext
   failedstring = "\n".join(failed)
   body = "%s\n\n%s" % (text3, failedstring)
  modal.dismiss()
  alert = UIAlertView.alloc().init()
  alert.setTitle_(title)
  alert.setBodyText_(body)
  alert.addButtonWithTitle_(string("ok"))
  alert.show()
