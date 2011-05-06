#!/Applications/AppBackup.app/Cycript

/* AppBackup
 * An iPhoneOS application that backs up and restores the saved data and
 * preferences of App Store apps.
 * 
 * Copyright (C) 2008-2011 Scott Zeid
 * http://me.srwz.us/iphone/appbackup
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * 
 * Except as contained in this notice, the name(s) of the above copyright holders
 * shall not be used in advertising or otherwise to promote the sale, use or
 * other dealings in this Software without prior written authorization.
 * 
 */

// GUI client

@class AppBackupGUI : UIApplication {}

- applicationDidFinishLaunching:notification {
 var gui_server = start_gui_server();
 self.gui_server_task_ = gui_server[0];
 self.gui_server_port_ = gui_server[1];
 var frame = [UIHardware fullScreenApplicationContentRect];
 self.window_ = [new UIWindow initWithFrame:frame];
 var bounds = [self.window_ bounds];
 self.webView_ = [new UIWebView init];
 [self.window_ addSubview:self.webView_];
 var url = "http://127.0.0.1:" + self.gui_server_port_ + "/";
 var nsurl = [NSURL URLWithString:url];
 [self.webView_ loadRequest:[NSURLRequest requestWithUrl:nsurl]];
 [self.window_ makeKeyAndVisible];
}

- applicationWillTerminate:notification {
 [self.gui_server_task_ terminate];
}

@end

function start_gui_server() {
 var manager = [new NSFileManager init];
 // Build and run command
 var path = [NSBundle.mainBundle bundlePath] + "/appbackup-gui-server";
 var languages = ""; // comma-separated list of preferred languages
 for (i in [NSBundle.mainBundle preferredLocalizations]) {
  var id = [NSLocale canonicalLanguageIdentifierFromString:i];
  languages += id.replace(/_+/g, "-").split("-", 1)[0] + ",";
 }
 languages = locales.replace(/\s/g, "").replace(/,*$/, "");
 var task = [new NSTask launchedTaskWithLaunchPath:path arguments:[languages]];
 // Get TCP port number for GUI server
 var port_file = "/tmp/appbackup.port";
 var port_file_exists = false;
 while (!port_file_exists)
  port_file_exists = [manager fileExistsAtPath:port_file];
 var port_file_handle = [NSFileHandle fileHandleForReadingAtPath:port_file];
 var port = Number([port_file_handle readDataToEndOfFile].replace(/\s/g, ""));
 // Return NSTask and TCP port number
 return [task, port];
}

// According to Saurik, the argv system will change, but it hasn't in 2 years
// as of writing this (2011-05-06).

var sh = new Functor(dlsym(RTLD_DEFAULT, "system"), "^c*");
var strdup = new Functor(dlsym(RTLD_DEFAULT, "strdup"), "^c*");

var argv = new (*char)[system.args.length + 1];
argv[system.args.length] = null;

for (i in system.args) argv[i] = strdup(system.args[i]);

UIApplicationMain(system.args.length, argv, "AppBackupGUI", "AppBackupGUI");
