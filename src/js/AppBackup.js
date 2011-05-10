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

// AppBackup CLI Bridge

@class AppBackup : NSObject {}
 - init {
  self = [super init];
  if (self) {
   self.apps = {}
   self.all_backed_up = self.any_backed_up = self.any_corrupted = false;
  }
  return self;
 }
 - doAction:action onApp:app {
  return [self runCmd:action withArgs:["--guid", app.guid]];
 }
 - doActionOnAllApps:action {
  return [self runCmd:action withArgs:["--all"]];
 }
 - findApps {
  var r = [self runCmd:"list"]
  if (r.success) self.apps = r.data;
  else self.apps = {};
  [self updateBackupInfo];
  return r;
 }
 - getBackupTimeTextForApp:app {
  if (!app.useable) return _("app_corrupted_list");
  if (app.ignored) return _("baktext_ignored");
  var date = app.backup_text;
  if (date) return sprintf(_("baktext_yes"), localize_date(date));
  return _("baktext_no");
 }
 - runCmd:cmd { return [self runCmd:cmd withArgs:[]]; }
 - runCmd:cmd withArgs:args {
  var abcmd = [new AppBackupCommand init];
  [abcmd runWithCmd:cmd args:args];
  return [abcmd waitForResult];
 }
 - starbucks {
  var r = [self runCmd:"starbucks"];
  if (r.success) return r.data;
  return r
 }
 - updateAppAtIndex:index {
  var app = self.apps[index];
  var new_app = [self runCmd:"list" withArgs:["--verbose", "--guid", app.guid]];
  if (new_app.found) {
   delete new_app.found;
   self.apps[index] = new_app;
   [self updateBackupInfo];
   return true;
  } else {
   delete self.apps[index];
   [self updateBackupInfo];
   return false;
  }
 }
 - updateBackupInfo {
  self.all_backed_up = Boolean(self.apps.length);
  self.any_backed_up = self.any_corrupted = false;
  for (app in self.apps) {
   if (self.apps[app].useable) {
    if (self.apps[app].backup_time && !self.apps[app].ignored)
     self.any_backed_up = true;
    else self.all_backed_up = false;
   } else self.any_corrupted = true
  }
 }
@end

@class AppBackupCommand : NSObject {}
 - init {
  self = [super init];
  if (self) {
   self.cmd  = "";
   self.args = [];
   self.task = null;
  }
  return self;
 }
 - getResult {
  if (![self.isFinished]) return null;
  var data = [[self.task standardOutput] readDataToEndOfFile];
  var output = String([new NSString initWithData:data encoding:4]);
  if (output) return json_parse(output);
  return false;
 }
 - isfinished {
  if (self.task) return Boolean([self.task isRunning]);
  return {cmd: self.cmd, success:false, exit_code:-1, data:"unknown error"};
 }
 - run {
  var path = get_file_path("appbackup-cli");
  var args = ["--json", self.cmd].concat(self.args);
  var task = [NSTask launchedTaskWithLaunchPath:path arguments:args];
 }
 - runWithCmd:cmd { return [self runWithCmd:cmd args:[]]; }
 - runWithCmd:cmd args:args {
  self.cmd  = cmd;
  self.args = args;
  [self run];
 }
 - waitForResult {
  var result = null;
  while (result == null)
   result = [self getResult];
  return result;
 }
@end
