#!/usr/bin/env python
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

# Remove comments from the file used to help sort Unicode strings

i = open("uca_keys.raw.txt")
o = open("uca_keys.txt", "w")

header = """# unidata-5.1.0.txt
# Date: 2008-03-04, 10:55:08 PST [KW]
#
# This file defines the Default Unicode Collation Element Table
#   (DUCET) for the Unicode Collation Algorithm
#
# Copyright (c) 2001-2008 Unicode, Inc.
# For terms of use, see http://www.unicode.org/terms_of_use.html
#
# See UTS #10, Unicode Collation Algorithm, for more information.
#
# Diagnostic weight ranges
# Primary weight range:   0200..3266 (12391)
# Secondary weight range: 0020..01DE (447)
# Variant secondaries:    01AF..01B4 (6)
# Digit secondaries:      01B5..01DE (42)
# Tertiary weight range:  0002..001F (30)
#
# Subsetted and comments removed.
#\n"""
o.write(header)

for line in i:
 if len(line) > 0:
  if not line.startswith("#"):
   oline = line.split("#")[0].rstrip()
   o.write(oline + "\n")

o.close()
i.close()
