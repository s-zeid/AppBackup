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

# Command-line interface

"""A command-line interface to AppBackup."""

usage = """Usage: appbackup [options] command [args]

Backs up and restores saved data and settings from iOS App Store apps.

Options:
 -j / --json     Output should be in JSON format.

Commands:
 -h / --help     Display this help information and exit.
 list [<app>]    Shows information about one or more App Store apps (all apps
                 if <app> is omitted).
 backup <app>    Back up the specified app's data.
 restore <app>   Restore the specified app's data.
 delete <app>    Delete the specified app's backup.
 ignore <app>    Ignore the specified app.
 unignore <app>  Stop ignoring the specified app.

Arguments for all commands:
 -a / --all      Perform the specified action on all App Store apps (not needed
                 for list).
 -g / --guid     A GUID is given as <app> instead of a bundle ID.
 <app>           The bundle IDs (or GUIDs if -g / --guid is set) for each app
                 you want to work with.

Arguments specific to list:
 -v / --verbose  Show more information for each app (implied when <app> is
                 given.)"""

import os
import sys

from string import Template

try:
 import json
except ImportError:
 import simplejson as json

from appbackup import *
from justifiedbool import *
from util import *
