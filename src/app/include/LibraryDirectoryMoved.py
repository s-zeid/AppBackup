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

# Code related to the Backups Moved message

# This is an Objective-C class.  You must do LibraryDirectoryMoved.alloc().init()
# to get a new instance.
class LibraryDirectoryMoved(UIActionSheet):
 # shown on first run after upgrading from 1.0.6 or earlier to 1.0.7 or later
 def init(self):
  self = super(LibraryDirectoryMoved, self).init()
  if self == None: return None
  self.setTitle_("Backups Moved")
  self.setBodyText_("Just in case you need to know, your backups have been moved from /var/mobile/Library/AppBackup to /var/mobile/Library/Preferences/ AppBackup so that iTunes will sync them.\n\nYou probably do not need to worry about this.")
  ok = self.addButtonWithTitle_(string("ok"))
  self.setCancelButtonIndex_(ok)
  return self
