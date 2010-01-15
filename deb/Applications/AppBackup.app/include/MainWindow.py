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

# Code related to the main window

class MainWindow(UIApplication):
 # how many rows the table will have
 @objc.signature("i@:@")
 def numberOfRowsInTable_(self, table):
  return len(shared.apps)

 # the table calls this to get the row contents for each row
 @objc.signature("@@:@i@@")
 def table_cellForRow_column_reusing_(self, table, row, col, reusing):
  app = shared.apps[row]
  if reusing is not None:
   cell = reusing
  else:
   cell = UIImageAndTextTableCell.alloc().init()

  # instead of doing cell.setTitle_ we're going to make 2
  # UITextLabels, one with the friendly name and the other with
  # the last backup time.  This is b/c I want to show both of
  # these to the user in a prettier way.  Also make a blank label
  # to go underneath them to prevent artifacts while scrolling.
  # The downside is that the row color doesn't change when selected.

  # Label 0 (the blank one to prevent artifacts)
  # Positioned at top-left of row
  # White background
  # 320px wide, 67px (row height - 1) high
  label0rect = ((0, 0), (320, 67))
  label0 = UITextLabel.alloc().initWithFrame_(label0rect)
  label0.setBackgroundColor_(UIColor.whiteColor())
  cell.addSubview_(label0)

  # Label 1
  # System font, bold, 20px, black if valid, gray if not
  # Clear background; positioned at 10, 8 from top-left of label0
  # 300px wide, 25px high
  label1rect = ((10, 8), (300, 25))
  font1 = UIFont.boldSystemFontOfSize_(20)
  label1 = UITextLabel.alloc().initWithFrame_(label1rect)
  label1.setFont_(font1)
  if app["useable"] == True:
   label1.setColor_(UIColor.blackColor())
  else:
   label1.setColor_(UIColor.grayColor())
  label1.setBackgroundColor_(UIColor.clearColor())
  label1.setText_(app["friendly"])
  label0.addSubview_(label1)

  # Label 2
  # System font, normal weight, 14px, gray
  # Clear background; positioned at 10, 38 from top-left of label0
  # 300px wide, 20 px high
  label2rect = ((10, 38), (300, 20))
  font2 = UIFont.systemFontOfSize_(14)
  label2 = UITextLabel.alloc().initWithFrame_(label2rect)
  label2.setFont_(font2)
  label2.setColor_(UIColor.grayColor())
  label2.setBackgroundColor_(UIColor.clearColor())
  label2.setText_(app["bak_text"])
  label0.addSubview_(label2)

  return cell

 # tableRowSelected_'s actual responsibilities have been moved into
 # include/BackupOne.py and is now the initWithAppIndex_ instance method of the
 # BackupOne class. This method just calls that one with the index in
 # shared.apps of the app that the user wants to back up or restore and shows
 # the resulting alert.
 # what to do when a table row is selected
 @objc.signature("v@:@@")
 def tableRowSelected_(self, notification, spam):
  obj = notification.object()
  cell = obj.cellAtRow_column_(obj.selectedRow(), 0)
  cell.setSelected_withFade_(False, True)
  BackupOne.alloc().initWithAppIndex_(obj.selectedRow()).popupAlertAnimated_(YES)

 # navigationBar_buttonClicked_'s actual responsibilities have been split into
 # class methods of the AboutBox and BackupAll classes, called buttonClicked.
 # They can be found in the include/AboutBox.py and include/BackupAll.py files.
 # This method just calls the correct buttonClicked instance method.
 # what to do when you click a navbar button
 @objc.signature("v@:@i")
 def navigationBar_buttonClicked_(self, bar, button):
  if button == 0: # About button
   self.aboutBox.popupAlertAnimated_(YES)
  elif button == 1: # All button
   BackupAll.alloc().init().popupAlertAnimated_(YES)

 # actionSheet_didDismissWithButtonIndex_ has been split into an instance
 # method of the AboutBox, BackupAll, and BackupOne classes that has the same
 # name.  They can be found in the include/AboutBox.py, include/BackupAll.py,
 # and include/BackupOne.py files.

 @objc.signature("v@:@")
 def applicationDidFinishLaunching_(self, unused):
  # make window
  outer = UIHardware.fullScreenApplicationContentRect()
  self.window = UIWindow.alloc().initWithFrame_(outer)
  self.window.setBackgroundColor_(UIColor.whiteColor())
  self.window.orderFront_(self)
  self.window.makeKey_(self)
  self.window.setHidden_(NO)
  inner = self.window.bounds()
  self.navsize = UINavigationBar.defaultSize()
  self.navrect = ((0, 0), (inner[1][0], self.navsize[1]))
  self.navrect2 = ((0, inner[1][1] - self.navsize[1]), (inner[1][0], self.navsize[1]))
  self.navrect3 = ((0, inner[1][1] - self.navsize[1] + 1), (inner[1][0], self.navsize[1]))
  self.view = UIView.alloc().initWithFrame_(inner)
  self.window.setContentView_(self.view)
  
  # make navbar 1 with title only
  self.navbar = UINavigationBar.alloc().initWithFrame_(self.navrect);
  self.navbar.setBarStyle_(0)
  navitem = UINavigationItem.alloc().initWithTitle_(string("main_window_title"))
  self.navbar.pushNavigationItem_(navitem)
  self.navbar.setDelegate_(self)
  self.view.addSubview_(self.navbar)
  
  # draw a UIToolbar under navbar 2 for cosmetic purposes
  self.toolbar = UIToolbar.alloc().initWithFrame_(self.navrect2)
  self.view.addSubview_(self.toolbar)
  
  # make table column and table, and add column to table
  col = UITableColumn.alloc().initWithTitle_identifier_width_("Name", "name", 320)
  lower = ((0, self.navsize[1]), (inner[1][0], inner[1][1] - (self.navsize[1] * 2)));
  shared.list = UITable.alloc().initWithFrame_(lower)
  shared.list.setSeparatorStyle_(1)
  shared.list.addTableColumn_(col)
  shared.list.setReusesTableCells_(YES)
  shared.list.setDelegate_(self)
  shared.list.setRowHeight_(68)
  self.view.addSubview_(shared.list)
  
  # show a HUD while we load the app list
  self.hud = UIProgressHUD.alloc().initWithWindow_(self.window)
  self.hud.setText_(string("please_wait"))
  self.hud.show_(YES)
  self.view.addSubview_(self.hud)
  
  # find AppStore apps for the 1st time, in a separate thread so the user sees
  # the HUD
  shared.times = dict(plist.read(shared.backuptimesfile))
  probing_thread = thread(find_apps, [self.launchPart2])
 
 # called within probing_thread to finish setting up the UI
 def launchPart2(self):
  # set up the about box
  self.aboutBox = AboutBox.alloc().init()
  
  # make navbar 2 and add buttons
  self.navbar2 = UINavigationBar.alloc().initWithFrame_(self.navrect3);
  self.navbar2.setBarStyle_(0)
  self.navbar2.showLeftButton_withStyle_rightButton_withStyle_(
   string("all_button"), 0,
   string("about_button"), 0
  )
  self.navbar2.setDelegate_(self)
  self.view.addSubview_(self.navbar2)

  # update the list
  shared.list.setDataSource_(self)
  shared.list.reloadData()

  # have we upgraded from <= 1.0.6 to >= 1.0.7?  If so, move the backups.
  if os.path.exists("/var/mobile/Library/AppBackup") and os.path.exists("/var/mobile/Library/AppBackup/This has been moved") == False:
   if os.path.exists("/var/mobile/Library/Preferences/AppBackup"):
    os.rename("/var/mobile/Library/Preferences/AppBackup", "/var/mobile/Library/Preferences/AppBackup.old")
   os.rename("/var/mobile/Library/AppBackup", "/var/mobile/Library/Preferences/AppBackup")
   shared.backups_moved = True
   os.mkdir("/var/mobile/Library/AppBackup")
   with open("/var/mobile/Library/AppBackup/This has been moved", "w") as f:
    f.write("This folder has been moved to /var/mobile/Library/Preferences/AppBackup since AppBackup version 1.0.7.")
   shared.libroot = "/var/mobile/Library/Preferences/AppBackup"
   shared.tarballs = shared.libroot+"/tarballs"
   shared.backuptimesfile = shared.libroot+"/backuptimes.plist"

  # hide the HUD
  self.hud.show_(NO)

  # Show an info message if we moved the backups earlier.
  if shared.backups_moved == True:
   LibraryDirectoryMoved.alloc().init().popupAlertAnimated_(YES)
  
  # get rolling!
  log("Finished setting up main window.")
 
 def applicationWillTerminate(self):
  log("Exiting...")
  sys.stdout.write("[%#.3f] AppBackup was conceived, written, and performed by Scott Wallace,\n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] with the help of:\n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] \n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] Dave Arter\n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] gojohnnyboi\n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] Contributors to the English Wikipedia\n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] People who have sent me bug reports\n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] \n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] Cydia: Jay Freeman (saurik)\n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] Package hosting: BigBoss\n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] German translation: Chris Zander\n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] Swedish translation: Magnus Palsson (with an o above the a in\n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] Palsson)\n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] Web hosting: Joyent\n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] Software used: Python, Ubuntu Linux, Firefox, gedit, GNOME,\n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] gnome-terminal, zsh, ssh, scp, dpkg, tail, ls, ln, cd, mv, cp, etc.\n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] Abusive App Store approval process: Apple\n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] Confusing UIKit framework documentation: Apple\n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] \n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] BBC Colour\n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] \n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] Copyright 2008-2009 Scott Wallace.\n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] AppBackup is released under the terms of the GNU General Public\n" % round(time.time() - __starttime__, 3))
  sys.stdout.write("[%#.3f] License, either version 2 or any later version of your choice.\n" % round(time.time() - __starttime__, 3))
