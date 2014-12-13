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

# Justified Boolean type

__all__ = ["JustifiedBool", "JB"]

from util import to_unicode

class JustifiedBool(object):
 def __init__(self, value=False, reason=None):
  self.__bool = bool(value)
  self.__reason = to_unicode(reason) if reason else ""
 def __int__(self):
  return int(self.__bool)
 def __nonzero__(self):
  return self.__bool
 def __repr__(self):
  return "JustifiedBool(%s, %s)" % (repr(self.__bool), repr(self.__reason))
 def __str__(self):
  return unicode(self).encode("utf8")
 def __unicode__(self):
  return "%s %s" % (str(self.__bool), "because %s" % self.__reason
                                      if self.__reason else "for no reason")
 @property
 def bool(self):
  return self.__bool
 @property
 def reason(self):
  return self.__reason

JB = JustifiedBool
