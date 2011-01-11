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
