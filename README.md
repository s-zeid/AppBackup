AppBackup  
=========
An iOS application that backs up and restores the saved data and
preferences of App Store apps.

Copyright (C) 2008-2014 Scott Zeid  
<https://s.zeid.me/projects/appbackup/>

This is the source tree for AppBackup.  AppBackup is mainly written in
Python 2.5 and Objective-C.


Contents
--------

 * Directory structure with descriptions for some files
 * Prerequisites for building
 * Building AppBackup
 * Running AppBackup in the iOS Simulator
 * License


Directory structure with descriptions for some files
----------------------------------------------------

* `data/`
    * `bundle/`  
      Files included in .app bundle, excluding subdirectories
    * `DEBIAN/`  
      Debian package control files
    * `images/`  
      GIMP and SVG source files for image resources
    * `usr/`  
      /usr/bin/appbackup{,-fix-permissions} launcher scripts
* `i18n/`  
   Translations in INI format and some conversion scripts
* `lib/`  
   3rd-party or other external libraries
    * `obj-c/`  
      BDSKTask and MBProgressHUD
* `out/`  
  Directory where generated .deb files (and temporary files from the build
  process) are stored.
    * `python/`  
        * `path/`  
          Contains the `easy_install`-ed Python packages that will be copied
          into the .deb file
        * `iosappbackup-<version>.tar.gz`  
          Python source distribution generated with `make sdist`.
* `src/`  
    * `cli-proxy/`  
      The CLI proxy client used in the iOS Simulator build.
    * `FixPermissions/` \*  
      FixPermissions (C; fixes storage directory permissions)
    * `gui/`  
      GUI source code and third-party libraries in Objective-C
        * `about.html/`  
          Generator for the HTML file used in the About screen
        * `AppBackupGUI.xcodeproj`  
          An Xcode project, *only* for use with iOS Simulator.
    * `python/`  
      Python packages that are part of AppBackup
        * `iosappbackup/`  
          AppBackup CLI Python package
        * `setup.py`  
          Defines dependencies, etc. for the Python package
* `Makefile` \*\*  
  Builds the AppBackup GUI, uses `easy_install` to download the Python
  dependencies, and builds the Debian package.  Can also install AppBackup
  on an iDevice via SSH.
* `config.dist` \*\*  
  Sample configuration file for the Makefile.  Should be copied to `config`,
  and then `config` should be modified as necessary.
* ...  

 `*` FixPermissions is changed to setuid root after the package is
     installed.

`**` See the Building AppBackup section for details.  AppBackupGUI and
     FixPermissions are re-compiled by default, but that can be changed.


Prerequisites for building
--------------------------

 * Linux (tested with Fedora; other distros, OS X, Cygwin, etc. may work
   but I haven't tested them)
 * Working iOS toolchain that uses clang (tested with a 3.1.2 toolchain)
 * bash; dpkg; GNU make; Python 2.5 (OS X only), 2.6, or 2.7
 * Python setuptools

At the time of this writing, I am using Fedora 20 and
[this toolchain](https://code.google.com/p/ios-toolchain-based-on-clang-for-linux/)
with the iOS 3.1.2 SDK to develop AppBackup.  The iOS device I use for
testing runs iOS 3.1.3.


Building AppBackup
------------------

Options for the build process are set in the `config` file.  You must create
the `config` file before building for the first time:

 * Copy `config.dist` to `config`.
 * Edit `config` as necessary.
 * Compiling binaries is enabled by default; make `CC` in `config` be blank
   to disable that.
 * Precompiled binaries are not included in the git repository, but you can
   extract them from a pre-made AppBackup Debian package and put them into
   the correct places in the source tree if you are only trying to change or
   rebuild the Python parts.

AppBackup is built using a Makefile.  The most common invocations are:

 * `make`  
   Compiles the binaries (if enabled) and builds the .deb file.
 
 * `make install DEVICE=<hostname/address>`  
   Installs the most recently built .deb file onto the given device.
   (If DEVICE is set in your `config` file, then you can omit the DEVICE
   argument if you want to install onto that device.)
 
 * `make test DEVICE=<hostname/address>`  
   Compiles the binaries (if enabled), builds the .deb file, installs the
   .deb file onto the given device, and then runs `ssh mobile@<DEVICE>`.
   (If DEVICE is set in your `config` file, then you can omit the DEVICE
   argument if you want to install onto that device.)

If you wish to use `make install` or `make test`, make sure your device
has an SSH server installed, and CHANGE THE ROOT AND MOBILE USERS' PASSWORDS.
You will also need to manually install the AppBackup package dependencies:

    $ sudo apt-get install bash coreutils-bin python setuptools

The Python version on your device must be at 2.5, 2.6, or 2.7.


Running AppBackup in the iOS Simulator
--------------------------------------

AppBackup can be run in a limited fashion in the iOS Simulator, and an Xcode
project is included at `src/gui/AppBackupGUI.xcodeproj` for this purpose.  (The
Xcode project can**not** be used to compile the regular version of AppBackup.)

You must have the iosapplist Python package installed first:

    $ sudo pip install --pre -U iosapplist

Before you run AppBackup in the simulator, you must run the following command
outside the simulator on the same machine, from the root directory of the source
tree:

    $ ./appbackup.test \
       -r ~/Library/Developer/CoreSimulator/Devices/<uuid>/data \
       --robot=plist shell-server --null

(You can, of course, point it to a different data directory.  That directory
should have the same directory structure as `/var/mobile` from a real device.)

AppBackup uses a command-line shell written in Python 2.5 to do its magic;
however, the iOS Simulator's dyld will refuse to run the CLI or its launcher
script, complaining that they are "built for Mac [sic] OS X".  Therefore, the
simulator version uses a proxy that connects to the shell server invoked as
above, which listens on localhost port 14121 and only accepts one connection
at a time.

The Xcode project sets the preprocessor directive `USE_CLI_PROXY` to enable this
behavior, regardless of whether the project is being built for the simulator.


License
-------

AppBackup is [free software](https://www.gnu.org/philosophy/free-sw.html),
which means that it respects your freedoms.  AppBackup is released under
the terms of the X11 License, and it also includes software released under
similar free, permissive licenses.  For the full text of the license and
copyright notices for AppBackup and all software included with it, see
[the LICENSE.txt file](http://code.s.zeid.me/appbackup/src/master/LICENSE.txt)
in the source repository.
