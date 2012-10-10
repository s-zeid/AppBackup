AppBackup  
An iOS application that backs up and restores the saved data and
preferences of App Store apps.

Copyright (C) 2008-2012 Scott Zeid  
[http://me.srwz.us/projects/appbackup](http://me.srwz.us/projects/appbackup)

This is the source tree for AppBackup.  AppBackup is mainly written in
Python 2.5 and Objective-C.

# Contents

 * Directory structure with descriptions for some files
 * Prerequisites for building
 * Building AppBackup
 * License

# Directory structure with descriptions for some files

 * `/`
   * `DEBIAN/`
     Debian package control files
   * `i18n/`
     Translations in INI format and some conversion scripts
   * `src/`
      * `about-html/`
        Generator for the HTML file used in the About screen
      * `bundle/`
        Files included in .app bundle, excluding subdirectories
      * `FixPermissions/`
        FixPermissions (C; fixes storage directory permissions) `*`
      * `gui/`
        GUI source code and third-party libraries in Objective-C
      * `images/`
        GIMP and SVG source files for image resources
      * `python/`
        AppBackup CLI Python package and 3rd-party Python modules
      * `usr/`
        /usr/bin/appbackup{,-fix-permissions} launcher scripts
   * `build`
     Build a Debian package (./build [device-hostname] [deb-file-prefix]) `**`
   * `config.dist`
     Configuration file for build and test `**`
   * `test`
     Script to test AppBackup on your own device (./test device-address) `**`
   * ...

 `*` FixPermissions is changed to setuid root after the package is
     installed.

`**` See the Building AppBackup section for details.  AppBackupGUI and
     FixPermissions are NOT re-compiled by default.

# Prerequisites for building

* Computer
   * Ubuntu Linux (other distros, OS X, Cygwin, etc. may work but I
     haven't tested them)
   * Working iOS toolchain that has GCC (tested with a 3.1.2 toolchain)
   * bash; dpkg; GNU make; OpenSSH client; Python 2.5 (OS X only), 2.6,
     or 2.7
* Device
   * Jailbroken iPhone, iPod touch, or iPad
   * Cydia (with at least the default sources)
   * bash, dpkg, ldid
   * OpenSSH server WITH THE ROOT AND MOBILE PASSWORDS CHANGED!
   * AppBackup package dependencies:
      * bash, coreutils-bin, python (versions >= 2.5 and < 3.0)

# Building AppBackup

To build a .deb file, run `build`.  To build a test package and install it
on an iDevice for testing, run `test`.

 * Add your devices's IP address or hostname at the end if `CC` is enabled
   in `config`, or if you are running `test`.
 * Make sure your device has the following installed if you are compiling
   or testing on it:
    * OpenSSH Server (CHANGE THE ROOT AND MOBILE USERS' PASSWORDS)
    * ldid
 * You can add a prefix for the .deb file's name at the end if you are
   running build and NOT test (test always uses the prefix `test_`.)
 * `test` will start an SSH session with your device when installation is
   finished.
 * Examples:
    * `$ ./build 192.168.7.16`
    * `$ ./build scottPhone test`
    * `$ ./test scottPhone`

Options for `build` and `test` are set in the `config` file.

 * Copy `config.dist` to `config`.
 * See `config` for available options.
 * Compiling binaries is disabled by default; set `CC` in `config` to
   enable it.
 * Precompiled binaries are included in the git repository.

This process has been tested on Ubuntu 11.04 with an iPhone 3.1.2 toolchain,
and an iPhone 2G running iOS 3.1.2.

# License

    AppBackup
    An iOS application that backs up and restores the saved data and
    preferences of App Store apps.

    Copyright (C) 2008-2012 Scott Zeid
    http://me.srwz.us/projects/appbackup

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.

    Except as contained in this notice, the name(s) of the above copyright holders
    shall not be used in advertising or otherwise to promote the sale, use or
    other dealings in this Software without prior written authorization.

    Localized strings for languages other than English were created by volunteers
    whose names are listed in the CREDITS file.

    This program contains the following libraries or portions of them:

     * BDSKTask (http://code.google.com/p/mactlmgr/):
	This software is Copyright (c) 2008-2012
	Adam Maxwell. All rights reserved.
	
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions
	are met:
	
	- Redistributions of source code must retain the above copyright
	notice, this list of conditions and the following disclaimer.
	
	- Redistributions in binary form must reproduce the above copyright
	notice, this list of conditions and the following disclaimer in
	the documentation and/or other materials provided with the
	distribution.
	
	- Neither the name of Adam Maxwell nor the names of any
	contributors may be used to endorse or promote products derived
	from this software without specific prior written permission.
	
	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
	A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
	OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
	SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
	LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
	DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
	THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
	OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

     * CFPropertyList (https://github.com/bencochran/CFPropertyList):
	CFPropertyList is made available under the terms of the MIT License.
	
	Copyright (c) 2010 Ben Cochran (http://bencochran.com)
	
	Permission is hereby granted, free of charge, to any person obtaining a copy 
	of this software and associated documentation files (the "Software"), to 
	deal in the Software without restriction, including without limitation the 
	rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
	sell copies of the Software, and to permit persons to whom the Software is 
	furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in 
	all copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
	IN THE SOFTWARE.

     * simplejson (http://pypi.python.org/pypi/simplejson/):
	Copyright (c) 2006 Bob Ippolito
	
	Permission is hereby granted, free of charge, to any person obtaining a copy of
	this software and associated documentation files (the "Software"), to deal in
	the Software without restriction, including without limitation the rights to
	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
	of the Software, and to permit persons to whom the Software is furnished to do
	so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

     * MBProgressHUD (https://github.com/jdg/MBProgressHUD):
	(with modifications by Jonathan George)
	
	This code is distributed under the terms and conditions of the MIT license. 
	
	Copyright (c) 2009 Matej Bukovinski
	
	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
