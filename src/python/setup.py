#!/usr/bin/env python2

# This file is public domain via CC0:
# <https://creativecommons.org/publicdomain/zero/1.0/>

from setuptools import setup, find_packages

setup(
 name="iosappbackup",
 version="3.0.dev11",
 description="Backs up and restores the saved data and settings of"
             " installed iOS App Store apps.",
 url="http://code.s.zeid.me/appbackup",
 author="Scott Zeid",
 author_email="s@zeid.me",
 license="X11 License:  https://tldrlegal.com/license/x11-license",
 classifiers=[
  "Development Status :: 3 - Alpha",
  "Environment :: Console",
  "Intended Audience :: End Users/Desktop",
  "Intended Audience :: System Administrators",
  "Natural Language :: English",
  "Operating System :: iOS",
  "Operating System :: MacOS :: MacOS X",
  "Operating System :: POSIX",
  "Operating System :: POSIX :: Linux",
  "Programming Language :: Python :: 2",
  "Programming Language :: Python :: 2.5",
  "Programming Language :: Python :: 2 :: Only",
  "Topic :: Software Development :: Libraries",
  "Topic :: Software Development :: Libraries :: Python Modules",
  "Topic :: System :: Archiving :: Backup",
  "Topic :: System :: Recovery Tools",
  "Topic :: System :: Systems Administration",
  "Topic :: Utilities",
 ],
 packages=find_packages(),
 install_requires=["argparse", "CFPropertyList", "simplejson"]
                 +["iosapplist>=3.0dev30"],
 entry_points={
  "console_scripts": [
    "iosappbackup=iosappbackup:main"
  ]
 },
)
