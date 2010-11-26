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

# Code related to the about box

# This is an Objective-C class.  You must do AboutBox.alloc().init() to get a
# new instance.
class AboutBox(UIActionSheet):
 # what to do when you click the "About" button
 def init(self):
  self = super(AboutBox, self).init()
  if self == None: return None
  self.setTitle_(shared.about_title)
  self.setDelegate_(self)
  self.setBodyText_(shared.about_text)
  web = self.addButtonWithTitle_(string("web_site"))
  ok = self.addButtonWithTitle_(string("ok"))
  self.setCancelButtonIndex_(ok)
  return self
 
 # what to do when you close the about box
 @objc.signature("v@:@i")
 def actionSheet_didDismissWithButtonIndex_(self, malert, index):
  action = malert.buttonTitleAtIndex_(index)
  if action == string("web_site"):
   url = NSURL.alloc().initWithString_(shared.web_site)
   UIApplication.sharedApplication().openURL_(url)
   sys.exit()
