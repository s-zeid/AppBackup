# AppBackup
# An iPhoneOS application that backs up and restores the saved data and
# preferences of App Store apps.
#
# Copyright (C) 2008-2010 Scott Wallace
# http://pages.srwz.us/iphone/appbackup
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
  action = malert.buttonTitleAtIndex_(index)
  if action != string("cancel"):
   # We're using a UIModalView so it doesn't show
   # the space where buttons go (we have no buttons)
   modal = UIModalView.alloc().init()
   modal.setTitle_(string("please_wait"))
   if action == string("backup"):
    text = string("all_status_backup_doing")
   if action == string("restore"):
    text = string("all_status_restore_doing")
   modal.setBodyText_(text)
   modal.popupAlertAnimated_(YES)
   actingThread = thread(self.onAllAppsDoAction_withModalView_, [action, modal])
 
 # act on all apps, close the given modal, and tell the user about the results
 def onAllAppsDoAction_withModalView_(self, action, modal):
  if action == string("backup"):
   text2 = string("all_status_backup_done")
   text3 = string("all_status_backup_failed")
   text4 = string("all_status_backup_corrupted")
   alldonetext = string("backup_done")
   allpartdonetext = string("backup_partially_done")
  if action == string("restore"):
   text2 = string("all_status_restore_done")
   text3 = string("all_status_restore_failed")
   text4 = string("all_status_restore_corrupted")
   alldonetext = string("restore_done")
   allpartdonetext = string("restore_partially_done")
  alldone = True
  failed = []
  corrupted = []
  any_corrupted = False
  position = 0
  for app in shared.apps:
   if app["useable"] == True:
    if action == string("backup"):
     ret = act_on_app(app, position, "Backup")
     if ret == False:
      alldone = False
      failed.append(app["friendly"])
     else:
      update_backup_time(position, ret, iterate=False)
      shared.list.reloadData()
    elif action == string("restore") and app["bak_time"] != None:
     ret = act_on_app(app, position, "Restore")
     if ret != True:
      alldone = False
      failed.append(app["friendly"])
   else:
    any_corrupted = True
    corrupted.append(app["friendly"])
    failed.append(app["friendly"] + " (corrupted)")
   position += 1
  if action == string("backup"):
   update_backup_time(iterateOnly=True)
   #find_apps()
   shared.list.reloadData()
  if alldone == True and any_corrupted == False:
   donetext = alldonetext
   use = text2
  elif alldone == True and any_corrupted == True:
   donetext = allpartdonetext
   corruptedstring = "\n".join(corrupted)
   use = "%s\n\n%s" % (text4, corruptedstring)
  else:
   donetext = allpartdonetext
   failedstring = "\n".join(failed)
   use = "%s\n\n%s" % (text3, failedstring)
  modal.dismiss()
  alert = UIAlertView.alloc().init()
  alert.setTitle_(donetext)
  alert.setBodyText_(use)
  alert.addButtonWithTitle_(string("ok"))
  alert.show()
