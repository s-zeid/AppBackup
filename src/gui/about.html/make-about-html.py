#!/usr/bin/env python

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

# About screen HTML generator

from __future__ import with_statement

import functools
import htmlentitydefs
import os
import plistlib
import sys

from string import Template

def htmlentities(text, exclude="\"&<>", table=htmlentitydefs.codepoint2name):
 if isinstance(text, list):
  out = []
  for i in text:
   out.append(htmlentities(i, exclude, table))
 elif isinstance(text, dict):
  out = {}
  for i in text:
   out[i] = htmlentities(text[i], exclude, table)
 elif isinstance(text, basestring):
  if isinstance(text, unicode):
   out = u""
  else:
   out = ""
  for i in text:
   if ord(i) in table and i not in exclude:
    out += "&" + table.get(ord(i)) + ";"
   else:
    out += i
 else:
  out = text
 return out

htmlspecialchars = functools.partial(htmlentities, exclude="",
                                     table={34: "quot", 38: "amp", 60: "lt",
                                            62: "gt"})

script = os.path.abspath(sys.argv[0])
repo_root = os.path.dirname(script)
for i in xrange(3):
 repo_root = os.path.dirname(repo_root)

os.chdir(repo_root)

info_plist = plistlib.readPlist(os.path.join("data", "bundle", "Info.plist"))
app_name   = htmlentities(info_plist["CFBundleDisplayName"], exclude="")
version    = htmlentities(info_plist["CFBundleShortVersionString"], exclude="")
tplvars    = dict(app_name=app_name, changelog="", credits="", license="",
                  template="document", version=version)

with open("CHANGELOG", "rb") as f:
 tplvars["changelog"] = htmlentities(unicode(f.read(), "utf8"), exclude="")
with open("CREDITS", "rb") as f:
 tplvars["credits"] = htmlentities(unicode(f.read(), "utf8"), exclude="")
with open("LICENSE.txt", "rb") as f:
 tplvars["license"] = htmlentities(unicode(f.read(), "utf8"), exclude="")
os.chdir(os.path.dirname(script))
with open("about-template.html", "rb") as f:
 tpl = unicode(f.read(), "utf8")

print Template(tpl).substitute(tplvars)
