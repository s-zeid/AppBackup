# AppBackup
# An iPhoneOS application that backs up and restores the saved data and
# preferences of App Store apps.
#
# Copyright (C) 2008-2009 Scott Wallace
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
  elif app["bak"] != None:
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
