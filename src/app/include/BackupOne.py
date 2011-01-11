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

# Code related to backing up or restoring one App Store app's data

# This is an Objective-C class.  You must do BackupOne.alloc().init() to get a
# new instance.
class BackupOne(UIActionSheet):
 # what to do when a table row is selected
 def initWithAppIndex_(self, index):
  self = super(BackupOne, self).init()
  if self == None: return None
  shared.current_app = index
  app = shared.apps[shared.current_app]
  self.setTitle_(app["friendly"])
  self.setDelegate_(self)
  canceltext = string("cancel")
  if app["useable"] == False:
   prompt = string("app_corrupted_prompt")
   canceltext = string("ok")
  elif app["ignore"] == True:
   unignore = self.addButtonWithTitle_(string("unignore"))
   prompt = string("app_ignored_prompt")
  elif app["bak_time"] != None:
   backup = self.addButtonWithTitle_(string("backup"))
   restore = self.addButtonWithTitle_(string("restore"))
   ignore = self.addButtonWithTitle_(string("ignore"))
   delete = self.addButtonWithTitle_(string("delete"))
   prompt = string("backup_restore_1_app")
  else:
   backup = self.addButtonWithTitle_(string("backup"))
   ignore = self.addButtonWithTitle_(string("ignore"))
   prompt = string("backup_1_app")
  cancel = self.addButtonWithTitle_(canceltext)
  self.setCancelButtonIndex_(cancel)
  self.setBodyText_(prompt)
  return self
 
 # what to do when you close the BackupOne prompt
 @objc.signature("v@:@i")
 def actionSheet_didDismissWithButtonIndex_(self, malert, index):
  action_localized = malert.buttonTitleAtIndex_(index)
  app = shared.apps[shared.current_app]
  if action_localized != string("cancel") and action_localized != string("ok"):
   # We're using a UIModalView so it doesn't show
   # the space where buttons go (we have no buttons)
   modal = UIModalView.alloc().init()
   modal.setTitle_(string("please_wait"))
   if action_localized == string("backup"):
    log("I'm about to back up the data of app %s" % escape_utf8(app["friendly"]))
    action = "backup"
   elif action_localized == string("restore"):
    log("I'm about to restore the data of app %s" % escape_utf8(app["friendly"]))
    action = "restore"
   elif action_localized == string("ignore"):
    log("I'm about to ignore app %s" % escape_utf8(app["friendly"]))
    action = "ignore"
   elif action_localized == string("unignore"):
    log("I'm about to unignore app %s" % escape_utf8(app["friendly"]))
    action = "unignore"
   elif action_localized == string("delete"):
    log("I'm about to delete the backup of app %s" % escape_utf8(app["friendly"]))
    action = "delete"
   app_name = app["friendly"] if action in ("ignore", "unignore") else app["possessive"]
   text = string("1_status_%s_doing" % action) % app_name
   modal.setBodyText_(text)
   modal.popupAlertAnimated_(YES)
   log("Notified user of this.  Starting thread for this action.")
   actingThread = thread(self.onOneAppDoAction_withModalView_, [action, modal])
  else:
   shared.current_app = None
 
 def onOneAppDoAction_withModalView_(self, action, modal):
  app = shared.apps[shared.current_app]
  app_name = app["friendly"] if action in ("ignore", "unignore") else app["possessive"]
  text2 = string("1_status_%s_done" % action) % app_name
  text3 = string("1_status_%s_failed" % action) % app_name
  donetext = string(action + "_done")
  failtext = string(action + "_failed")
  results_box = True
  if action == "backup":
   log("Now backing up data of %s..." % app["friendly"])
   ret = act_on_app(app, shared.current_app, "Backup")
   if ret != False:
    log("Backup was successful.  Saving backup time.")
    update_backup_time(shared.current_app, ret)
    #log("Finding apps again...")
    #find_apps()
    shared.list.reloadData()
    time.sleep(1)
    title = donetext
    body = text2
   else:
    log("Backup was NOT successful!")
    title = failtext
    body = text3
  elif action == "restore":
   log("Now restoring data of %s..." % escape_utf8(app["friendly"]))
   ret = act_on_app(app, shared.current_app, "Restore")
   if ret == True:
    log("Restore was successful.")
    title = donetext
    body = text2
   else:
    log("Restore was NOT successful!")
    title = failtext
    body = text3
  elif action in ("ignore", "unignore"):
   log("Now %signoring data of %s..." % ("un" if action == "unignore" else "",
                                         escape_utf8(app["friendly"])))
   ret = toggle_ignore(shared.current_app)
   if ret == True:
    log("(Un)ignoring was successful.")
    results_box = False
   else:
    log("(Un)ignoring was NOT successful!")
    title = failtext
    body = text3
   shared.list.reloadData()
   time.sleep(1)
  elif action == "delete":
   log("Now deleting backup of %s..." % escape_utf8(app["friendly"]))
   ret = act_on_app(app, shared.current_app, "Delete")
   if ret == True:
    log("Deletion was successful.")
    update_backup_time(shared.current_app, None)
    shared.list.reloadData()
    time.sleep(1)
    title = donetext
    body = text2
   else:
    log("Deletion was NOT successful!")
    title = failtext
    body = text3
  modal.dismiss()
  log("Dismissed modal view.")
  shared.current_app = None
  if results_box:
   alert = UIAlertView.alloc().init()
   alert.setTitle_(title)
   alert.setBodyText_(body)
   alert.addButtonWithTitle_(string("ok"))
   log("Notifying user of results.")
   alert.show()
