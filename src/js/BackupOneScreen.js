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

// Backup One App screen

@class _BackupOneScreen : UIActionSheet {}
 // What to do when a table row is selected
 - init {
  return [super init];
 }
@end
_BackupOneScreen.prototype.setup = function(gui, index) {
 if (this) {
  this.gui = gui;
  this.index = index;
  this.app = gui.appbackup.apps[index];
  [this setTitle:app.friendly];
  [this setDelegate:[new _BackupOneScreenDelegate init].setup(gui, index, app)];
  if (prompt.length <= 30) var prompt = ["(" + app.bundle + ")"];
  else var prompt = ["(" + prompt.slice(0, 30) + "...)"];
  var cancel_string = "cancel";
  if (!app.useable) {
   prompt.push(_("app_corrupted_prompt"));
   cancel_string = "ok";
  } else if (app.ignored) {
   prompt.push(_("app_ignored_prompt"));
   [this addButtonWithTitle:_("unignore")];
  } else if (app.backup_time) {
   [this addButtonWithTitle:_("backup")];
   [this addButtonWithTitle:_("restore")];
   [this addButtonWithTitle:_("ignore")];
   [this addButtonWithTitle:_("delete")];
  } else {
   [this addButtonWithTitle:_("backup")];
   [this addButtonWithTitle:_("ignore")];
  }
  [this setBodyText:prompt.join("\n\n")];
  [this setCancelButtonIndex:[this addButtonWithTitle:_(cancel_string)]];
 }
 return this;
}

@class _BackupOneScreenDelegate : NSObject <UIActionSheetDelegate> {}
 // What to do when you close the backup one app prompt
 - actionSheet:sheet didDismissWithButtonIndex:index {
  var button_text = [sheet buttonTitleAtIndex:index];
  if (button_text == _("cancel") || button_text == _("ok")) return;
  self.modal = [new UIModalView init];
  [self.modal setTitle:_("please_wait")];
  for (i in ["backup", "delete", "ignore", "restore", "unignore"]) {
   if (button_text == _(i)) {
    self.action = i;
    break;
   }
  }
  self.str_prefix = "1_status_" + self.action + "_";
  var text = sprintf(_(self.string_prefix + "doing"), self.app.friendly);
  [self.modal setBodyText:text];
  [self.modal popupAlertAnimated:true];
  self.do_action(action);
 }
@end
_BackupOneScreenDelegate.prototype.setup = function(gui, index, app) {
 if (this) {
  this.gui   = gui;
  this.index = index;
  this.app   = app;
 }
 return this
}
_BackupOneScreenDelegate.prototype.do_action = function(action) {
 var done_title   = _(action + "done");
 var done_text    = sprintf(_(this.str_prefix + "done"), this.app.friendly);
 var failed_title = _(action + "failed");
 var failed_text  = sprintf(_(this.str_prefix + "failed"), this.app.friendly);
 var results_box  = true;
 var r = this.gui.appbackup.do_action(action, this.app);
 this.gui.update_app_at_index(this.index);
 if (r.success) {
  var title   = done_title;
  var text    = done_text;
  if (action == "ignore" || action == "unignore")
   resutls_box = false;
 } else {
  var title   = failed_title;
  var text    = failed_text;
 }
 [this.modal dismiss];
 if (results_box) {
  this.alert = [new UIAlertView init];
  [this.alert setTitle:title];
  [this.alert setBodyText:text];
  [this.alert addButtonWithTitle:_("ok")];
  [this.alert show];
 }
}

var BackupOneScreen = _BackupOneScreen;
