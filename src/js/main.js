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

// GUI Runner

function _(s) {
 return String([NSBundle.mainBundle localizedStringForKey:s value:""
                table:null]);
}
function bundled_file_path(file) {
 return String([NSBundle.mainBundle bundlePath]) + "/" + file;
}
function file_exists(path) {
 return Boolean([[new NSFileManger init] fileExistsAtPath:path]);
}
function get_languages() {
 var list = CFLocaleCopyPreferredLanguages();
 var languages = [];
 for (i in list) languages += list[i].replace(/_+/g, "-").split("-", 1)[0];
 return languages;
}
function include(file) {
 eval(read(file));
}
function localize_date(date) {
 if (!date) return "";
 var iso_8601_formatter = [new NSDateFormatter init];
 [iso_8601_formatter setDateFormat:"yyyy-MM-dd HH:mm:ss"];
 var nsdate = [iso_8601_formatter dateFromString:date];
 var local_formatter = [new NSDateFormatter init];
 [local_formatter setDateStyle:2];
 [local_formatter setTimeStyle:1]
 var out = [local_date_formatter stringFromDate:nsdate];
 if (!out) {
  var generic_formatter = [new NSDateFormatter init];
  [generic_formatter setDateFormat:"MMM d, yyyy h:mm a"];
  out = [generic_formatter stringFromDate:nsdate];
  if (!out) out = date;
 }
 return String(out);
}
function main() {
 // According to Saurik, the argv system will change, but it hasn't in 2 years
 // as of writing this (2011-05-06).
 var argv = new (*char)[system.args.length + 1];
 argv[system.args.length] = null;
 for (i in system.args) argv[i] = strdup(system.args[i]);
 UIApplicationMain(system.args.length, argv, "AppBackupGUI", "AppBackupGUI");
}
function read(file) {
 return String([NSString stringWithContentsOfFile:file encoding:4 error:null]);
}

include(bundled_file_path("js/json_parse.js"));
include(bundled_file_path("js/sprintf.js"));
include(bundled_file_path("js/AboutScreen.js"));
include(bundled_file_path("js/AppBackup.js"));
include(bundled_file_path("js/AppBackupGUI.js"));
include(bundled_file_path("js/BackupAllScreen.js"));
include(bundled_file_path("js/BackupOneScreen.js"));

var strdup = new Functor(dlsym(RTLD_DEFAULT, "strdup"), "^c*");

var PRODUCT = {
 name: String([NSBundle.mainBundle
               objectForInfoDictionaryKey:"CFBundleDisplayName"]),
 web_site: "http://me.srwz.us/iphone/appbackup"
};

main();
