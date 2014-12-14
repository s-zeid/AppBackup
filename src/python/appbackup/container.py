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

# MobileContainer stuffs

from __future__ import with_statement

import os
import re

import propertylist

from util import *

__all__ = [
 "CONTAINER_METADATA_PLIST",
 "ContainerError",
 "Container",
 "ContainerClass",
 "ContainerRoot",
]


CONTAINER_METADATA_PLIST = u".com.apple.mobile_container_manager.metadata.plist"


class ContainerError(Exception): pass


class Container(object):
 """Describes a UUID-named iOS container or legacy (iOS <= 7.x) app directory.

Attributes:
 class_:    the class of the container (a ContainerClass object)
 class_raw: the raw value of the "MCMMetadataContentClass" key in the
             metadata plist
 bundle_id: the corresponding bundle ID
 uuid:      the directory name of the container; will be a UUID string
 path:      the full path of the container directory
 plist:     the path to the metadata plist
 metadata:  the contents of the metadata plist as a Python dictionary

If class_ is ContainerClass.LEGACY, then that means it is not actually a
container, but rather an old-style ~mobile/Applications subdirectory from
iOS <= 7.x.  class_raw will be None.  metadata and plist will also be None,
as there will be no `.com.apple.mobile_container_manager.metadata.plist` file
to speak of.  The directory will be searched for an app bundle, and if one
exists and has an Info.plist file, then bundle_id will be set to the value
of "CFBundleIdentifier" in the app bundle's Info.plist file; otherwise,
bundle_id will be None.

If class_ is ContainerClass.UNKNOWN, then that means that this type of
container is unknown.  class_raw, metadata, plist, and bundle will likely
have their normal values, depending on the mood of the iOS developers.

"""
 
 def __init__(self, path):
  """Loads the container's info.  path is the path to the container."""
  self.path      = os.path.abspath(path)
  self.uuid      = os.path.basename(self.path).upper()
  self.plist     = os.path.join(self.path, CONTAINER_METADATA_PLIST)
  self.class_    = self.class_raw = None
  self.bundle_id = None
  self.metadata  = None
  if os.path.isfile(os.path.realpath(self.plist)):
   try:
    self.metadata = propertylist.load(self.plist)
    if "MCMMetadataContentClass" in self.metadata:
     self.class_raw = self.metadata["MCMMetadataContentClass"]
     self.class_    = ContainerClass.get(self.class_raw, ContainerClass.UNKNOWN)
    if "MCMMetadataIdentifier" in self.metadata:
     self.bundle_id = self.metadata["MCMMetadataIdentifier"]
   except propertylist.PropertyListError, exc:
    raise ContainerError(exc)
  else:
   self.plist     = None
   self.class_raw = ContainerClass.LEGACY.value
   self.class_    = ContainerClass.LEGACY
   for i in os.listdir(self.path):
    app_dir = os.path.realpath(os.path.join(self.path, i))
    if (os.path.isdir(app_dir) and i.endswith(u".app")):
     info_plist = os.path.join(app_dir, u"Info.plist")
     try:
      if os.path.isfile(os.path.realpath(info_plist)):
       pl = propertylist.load(info_plist)
       if "CFBundleIdentifier" in pl:
        self.bundle_id = pl["CFBundleIdentifier"]
     except propertylist.PropertyListError:
      pass
     break


class ContainerClass(object):
 """A psuedo-enum object documenting iOS container class types.

Each item in this psuedo-enum is a psuedo-namedtuple with two read-only fields:
name and value.

The items can be accessed in one of several ways:

 ContainerClass.<name>
 ContainerClass.get(<name>[, default=None])
 ContainerClass.get(<value>[, default=None])
 ContainerClass[<name>]
 ContainerClass[<value>]

Iteration will yield each individual item one time in the order listed below,
and not names and values by themselves.

Known container classes:
 <name> (<value>):  <description>
 --------------------------------
 BUNDLE (1):        a Bundle-class container (contains an app bundle)
 DATA   (2):        a Data-class container (contains an app's data)

Psuedo-classes:
 <name>  (<value>):         <description>
 ----------------------------------------
 UNKNOWN (NotImplemented):  an unknown class of container
 LEGACY  (None):            an old-style (iOS <= 7.x) app directory with
                             both an app bundle and its data

"""
 # I'm not using a namedtuple because (a) it's not in Python 2.5, and
 # (b) I like using actual class syntax for this in absence of a real enum type.
 
 # allows subscripting and iteration to work
 class __meta(type):
  def __getitem__(cls, item):
   return cls.__getitem__(item)
  def __iter__(cls):
   return cls.__iter__()
 __metaclass__ = __meta
 
 __items = {}
 __names = []
 
 def __new__(cls, name, value):
  # hack hack hackity hack
  class item(cls):
   __doc__ = cls.__doc__
   def __new__(item_cls):
    return object.__new__(item_cls)
   @property
   def name(self):
    return name
   @property
   def value(self):
    return value
   def __repr__(self):
    return "<%s.%s (value=%s)>" % (cls.__name__, self.name, repr(self.value))
   def __str__(self):
    return repr(self)
   def __unicode__(self):
    return repr(self).decode("utf-8")
  r = item()
  r.__name__ = cls.__name__
  return r
 
 @classmethod
 def __add(cls, *args, **kwargs):
  # Calls cls() with the arguments, and adds the resulting psuedo-namedtuple
  # to cls.__items (by both name and value) and makes an attribute with the
  # item's name on cls itself.
  item = cls(*args, **kwargs)
  if item.name in cls.__items:
   raise ValueError("%s is already in %s.__items" % (repr(item.name), cls.__name__))
  if item.value in cls.__items:
   raise ValueError("%s is already in %s.__items" % (repr(item.value), cls.__name__))
  setattr(cls, item.name, item)
  cls.__items[item.name]  = item
  cls.__items[item.value] = item
  cls.__names += [item.name]
 
 @classmethod
 def __getitem__(cls, item):
  return cls.__items[item]
 
 @classmethod
 def __iter__(cls):
  for i in cls.__names:
   yield cls[i]
 
 @classmethod
 def get(cls, key, default=None):
  return cls.__items.get(key, default)
 
 @classmethod
 def keys(cls):
  return sorted(cls.__items.keys())
 
ContainerClass.es = ContainerClass  # lets you type "ContainerClass.es"

# Known container classes
ContainerClass._ContainerClass__add("BUNDLE",  1)
ContainerClass._ContainerClass__add("DATA",    2)

# Psuedo-classes
ContainerClass._ContainerClass__add("UNKNOWN", NotImplemented)
ContainerClass._ContainerClass__add("LEGACY",  None)


class ContainerRoot(object):
 """Describes a directory containing iOS containers or legacy apps.

Attributes:
 input:       The argument given to the class's constructor, converted to a
               `unicode` object.
 path:        The path to the directory containing iOS containers or legacy app
               directories (i.e. "~mobile/Containers", "~mobile/Applications"
               or a directory with an equivalent structure).
 min_ios:     The minimum iOS version that could have the directory structure
               within `path`.
 bundle_root: The path to the bundle containers (min_ios >= 8 only) or None.
 data_root:   The path to the data containers (min_ios >= 8 only) or None.
 legacy_root: The path to the legacy app directories (min_ios < 8 only) or None.

"""
 @staticmethod
 def _has_uuids(path):
  for i in os.listdir(path):
   if re.search(r"^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$", i, re.I):
    return True
  return False
 
 def __init__(self, input):
  """Searches for the container root based on the input argument.

The input can be "/var/mobile", an iOS 8 "Containers" directory, its "Bundle"
or "Data" subdirectories, their "Application" subdirectory, the "Applications"
directory from iOS <= 7.x, or a directory with an eqivalent structure to any
of those (e.g. the "data" directory from an iOS Simulator instance).

"""
  self.input       = os.path.abspath(to_unicode(input))
  self.min_ios     = None
  self.path = path = input
  self.bundle_root = None
  self.data_root   = None
  self.legacy_root = None
  
  ls = os.listdir(path)
  if "Containers" in ls:
   self.min_ios = 8
   self.path = os.path.join(path, "Containers")
  elif "Bundle" in ls or "Data" in ls:
   self.min_ios = 8
   self.path = path
  elif "Applications" in ls:
   self.min_ios = 2
   self.path = os.path.join(path, "Applications")
  else:
   input_name = os.path.basename(path)
   parent = os.path.dirname(path)
   parent_name = os.path.basename(parent)
   grandparent = os.path.dirname(parent)
   if input_name == "Application":
    if parent_name == "Bundle":
     bundle_dir = parent
     data_dir = os.path.join(grandparent, "Data")
     if os.path.isdir(os.path.realpath(data_dir)):
      if self.has_uuids(bundle_dir) or self.has_uuids(data_dir):
       self.min_ios = 8
       self.path = grandparent
    elif parent_name == "Data":
     bundle_dir = os.path.join(grandparent, "Bundle")
     data_dir = parent
     if os.path.isdir(os.path.realpath(bundle_dir)):
      if self.has_uuids(data_dir) or self.has_uuids(bundle_dir):
       self.min_ios = 8
       self.path = grandparent
    if self.min_ios == None:
     self.min_ios = 2
     self.path = path
   elif input_name == "Bundle":
    bundle_dir = path
    data_dir = os.path.join(parent, "Data")
    if os.path.isdir(os.path.realpath(data_dir)):
     if self.has_uuids(bundle_dir) or self.has_uuids(data_dir):
      self.min_ios = 8
      self.path = parent
   elif input_name == "Data":
    bundle_dir = os.path.join(parent, "Bundle")
    data_dir = path
    if os.path.isdir(os.path.realpath(bundle_dir)):
     if self.has_uuids(data_dir) or self.has_uuids(bundle_dir):
      self.min_ios = 8
      self.path = parent
   if self.min_ios == None:
    self.min_ios = 2
    self.path = path
  if self.min_ios == None:
   self.min_ios = 2
   self.path = path
  path = self.path
  if self.min_ios >= 8:
   self.bundle_root = os.path.join(path, "Bundle", "Application")
   self.data_root   = os.path.join(path, "Data",   "Application")
  if self.min_ios < 8:
   self.legacy_root = path
