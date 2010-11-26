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
  if app["useable"] == False:
   prompt = string("app_corrupted_prompt")
   canceltext = string("ok")
  elif app["bak_time"] != None:
   backup = self.addButtonWithTitle_(string("backup"))
   restore = self.addButtonWithTitle_(string("restore"))
   prompt = string("backup_restore_1_app")
   canceltext = string("cancel")
  else:
   backup = self.addButtonWithTitle_(string("backup"))
   prompt = string("backup_1_app")
   canceltext = string("cancel")
  cancel = self.addButtonWithTitle_(canceltext)
  self.setCancelButtonIndex_(cancel)
  self.setBodyText_(prompt)
  return self
 
 # what to do when you close the BackupOne prompt
 @objc.signature("v@:@i")
 def actionSheet_didDismissWithButtonIndex_(self, malert, index):
  action = malert.buttonTitleAtIndex_(index)
  app = shared.apps[shared.current_app]
  if action != string("cancel") and action != string("ok"):
   # We're using a UIModalView so it doesn't show
   # the space where buttons go (we have no buttons)
   modal = UIModalView.alloc().init()
   modal.setTitle_(string("please_wait"))
   if action == string("backup"):
    log("I'm about to back up the data of app %s" % escape_utf8(app["friendly"]))
    text = string("1_status_backup_doing") % app["possessive"]
   if action == string("restore"):
    log("I'm about to restore the data of app %s" % escape_utf8(app["friendly"]))
    text = string("1_status_restore_doing") % app["possessive"]
   modal.setBodyText_(text)
   modal.popupAlertAnimated_(YES)
   log("Notified user of this.  Starting thread for this action.")
   actingThread = thread(self.onOneAppDoAction_withModalView_, [action, modal])
  else:
   shared.current_app = None
 
 def onOneAppDoAction_withModalView_(self, action, modal):
  app = shared.apps[shared.current_app]
  if action == string("backup"):
   text2 = string("1_status_backup_done") % app["possessive"]
   text3 = string("1_status_backup_failed") % app["possessive"]
   log("Now backing up data of %s..." % app["friendly"])
   ret = act_on_app(app, shared.current_app, "Backup")
   if ret != False:
    log("Backup was successful.  Saving backup time.")
    update_backup_time(shared.current_app, ret)
    #log("Finding apps again...")
    #find_apps()
    shared.list.reloadData()
    donetext = string("backup_done")
    use = text2
   else:
    log("Backup was NOT successful!")
    donetext = string("backup_failed")
    use = text3
  if action == string("restore"):
   text2 = string("1_status_restore_done") % app["possessive"]
   text3 = string("1_status_restore_failed") % app["possessive"]
   log("Now restoring data of %s..." % escape_utf8(app["friendly"]))
   ret = act_on_app(app, shared.current_app, "Restore")
   if ret == True:
    log("Restore was successful.")
    donetext = string("restore_done")
    use = text2
   else:
    log("Restore was NOT successful!")
    donetext = string("restore_failed")
    use = text3
  modal.dismiss()
  log("Dismissed modal view.")
  alert = UIAlertView.alloc().init()
  alert.setTitle_(donetext)
  alert.setBodyText_(use)
  alert.addButtonWithTitle_(string("ok"))
  log("Notifying user of results.")
  alert.show()
  shared.current_app = None
