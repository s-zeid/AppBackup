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

function AppBackup() {
 this.apps = {}
 this.all_backed_up = this.any_backed_up = this.any_corrupted = false;
 this.do_action = function(action, app) {
  if (typeof(app) != "undefined")
   return this.run_cmd(action, ["--guid", app.guid]);
  else
   return this.run_cmd(action, ["--all"])
 }
 this.find_apps = function() {
  var r = this.run_cmd("list");
  if (r.success) this.apps = r.data;
  else this.apps = {};
  this.update_backup_info();
  return r;
 }
 this.get_backup_time_text = function(app) {
  if (!app.useable) return _("app_corrupted_list");
  if (app.ignored) return _("baktext_ignored");
  var date = app.backup_text;
  if (date) return sprintf(_("baktext_yes"), localize_date(date));
  return _("baktext_no");
 }
 this.run_cmd = function(cmd, args) {
  if (typeof(args) == "undefined")
   args = [];
  var abcmd = new AppBackupCommand(cmd, args);
  return abcmd.run(true);
 }
 this.starbucks = function() {
  var r = this.run_cmd("starbucks");
  if (r.success) return r.data;
  return r
 }
 this.update_app_at_index = function(index) {
  var app = this.apps[index];
  var new_app = this.run_cmd("list", ["--verbose", "--guid", app.guid]);
  if (new_app.found) {
   delete new_app.found;
   this.apps[index] = new_app;
   this.update_backup_info();
   return true;
  } else {
   delete this.apps[index];
   this.update_backup_info();
   return false;
  }
 }
 this.update_backup_info = function() {
  this.all_backed_up = Boolean(this.apps.length);
  this.any_backed_up = this.any_corrupted = false;
  for (app in this.apps) {
   if (this.apps[app].useable) {
    if (this.apps[app].backup_time && !this.apps[app].ignored)
     this.any_backed_up = true;
    else this.all_backed_up = false;
   } else this.any_corrupted = true
  }
 }
}

function AppBackupCommand(cmd, args) {
 if (typeof(args) == "undefined") args = [];
 this.task = null;
 this.get_result = function() {
  if (!this.is_finished()) return null;
  var data = [[this.task standardOutput] readDataToEndOfFile];
  var output = String([new NSString initWithData:data encoding:4]);
  if (output) return json_parse(output);
  return {cmd: this.cmd, success:false, exit_code:-1, data:"unknown error"};
 }
 this.is_finished = function() {
  if (this.task) return Boolean([this.task isRunning]);
  return false;
 }
 this.run = function(wait) {
  if (typeof(wait) == "undefined") wait = false;
  var path = get_file_path("appbackup-cli");
  var args = ["--json", this.cmd].concat(this.args);
  var task = [NSTask launchedTaskWithLaunchPath:path arguments:args];
  if (wait) {
   var result = null;
   while (result == null)
    result = this.get_result();
   return result;
  }
 }
}
