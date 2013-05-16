#!/usr/bin/env python

# AppBackup
# An iOS application that backs up and restores the saved data and
# preferences of App Store apps.
#
# Copyright (C) 2008-2013 Scott Zeid
# http://s.zeid.me/projects/appbackup/
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

# Converts a Localizable.strings file into an INI file suitable for uploading
# to Transifex.

import os
import re
import sys
import traceback

import yaml

if len(sys.argv) != 3:
 "Usage: %s in-file out-file" % os.path.basename(sys.argv[0])
 sys.exit(2)

in_file = os.path.abspath(sys.argv[1])
out_file = os.path.abspath(sys.argv[2])

print "Converting %s..." % in_file
with open(in_file, "rb") as f:
 t = unicode(f.read(), "utf8") + "\n"
if "%s" in t:
 print "warning: %s contains one or more occurrences of %%s" % in_file
t = re.compile(r"\/\*.*?\*\/", re.MULTILINE|re.DOTALL|re.UNICODE).sub("", t)
t = t.replace('" = "', '": "')
t = t.replace('; \n', '\n')
t = t.replace(';\n', '\n')
t = "\n".join([i.strip() for i in t.strip().splitlines()])
y = yaml.load(t)
o = []
keys = sorted(y.keys())
for k in keys:
 if k.strip() and y[k].strip():
  o += ['%s=%s' % (k, y[k])]
o = "\n".join(o)
with open(out_file, "wb") as f:
 f.write(o.encode("utf8"))
