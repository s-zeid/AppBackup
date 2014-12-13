# AppBackup
# An iOS application that backs up and restores the saved data and
# preferences of App Store apps.
#
# Copyright (C) 2008-2014 Scott Zeid
# https://s.zeid.me/projects/appbackup/
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

# Plist Library

"""A module to work with binary or XML plists."""

import plistlib

from xml.parsers.expat import ExpatError

import CFPropertyList

class PropertyListError(Exception): pass

def load(filename):
 """Reads a binary or XML plist from the given file name and returns the resulting dictionary."""
 cfplist = CFPropertyList.CFPropertyList(filename)
 cfplist.load()
 if cfplist.value != None:
  return CFPropertyList.native_types(cfplist.value)
 else:
  try:
   return plistlib.readPlist(filename)
  except ExpatError:
   raise PropertyListError(filename + " is not a valid binary or XML property"
                           " list file")

def save(value, filename):
 """Writes a dictionary to an XML plist with the give file name."""
 plistlib.writePlist(value, filename)
