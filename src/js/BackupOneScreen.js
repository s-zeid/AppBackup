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

@class BackupOneScreen : UIActionSheet {}
 // What to do when a table row is selected
 - initWithGUI:gui appAtIndex:index {
  self = [super init];
  if (self) {
   self.gui = gui;
   self.index = index;
   self.app = gui.appbackup.apps[index];
   [self setTitle:app.friendly];
   [self setDelegate:self];
   if (prompt.length <= 30) var prompt = ["(" + app.bundle + ")"];
   else var prompt = ["(" + prompt.slice(0, 30) + "...)"];
   var cancel_string = "cancel";
   if (!app.useable) {
    prompt.push(_("app_corrupted_prompt"));
    cancel_string = "ok";
   } else if (app.ignored) {
    prompt.push(_("app_ignored_prompt"));
    [self addButtonWithTitle:_("unignore")];
   } else if (app.backup_time) {
    [self addButtonWithTitle:_("backup")];
    [self addButtonWithTitle:_("restore")];
    [self addButtonWithTitle:_("ignore")];
    [self addButtonWithTitle:_("delete")];
   } else {
    [self addButtonWithTitle:_("backup")];
    [self addButtonWithTitle:_("ignore")];
   }
   [self setBodyText:prompt.join("\n\n")];
   [self setCancelButtonIndex:[self addButtonWithTitle:_(cancel_string)]];
  }
  return self;
 }
 // What to do when you close the backup one app prompt
 - actionSheet:sheet didDismissWithButtonIndex:index {
  var button_text = [sheet buttonTitleAtIndex:index];
  if (button_text == _("cancel") || button_text == _("ok")) return;
  modal = [new UIModalView init];
  [modal setTitle:_("please_wait")];
  for (i in ["backup", "delete", "ignore", "restore", "unignore"]) {
   if (button_text == _(i)) {
    self.action = i;
    break;
   }
  }
  self.str_prefix = "1_status_" + self.action + "_";
  var text = sprintf(_(self.string_prefix + "doing"), self.app.friendly);
  [modal setBodyText:text];
  [modal popupAlertAnimated:true];
 }
 - doAction:action withModalView:modal {
  var done_title   = _(action + "done");
  var done_text    = sprintf(_(self.str_prefix + "done"), self.app.friendly);
  var failed_title = _(action + "failed");
  var failed_text  = sprintf(_(self.str_prefix + "failed"), self.app.friendly);
  var results_box  = true;
  var r = [self.gui.appbackup doAction:action onApp:self.app];
  [self.gui updateAppAtIndex:self.index];
  if (r.success) {
   var title   = done_title;
   var text    = done_text;
   if (action == "ignore" || action == "unignore")
    resutls_box = false;
  } else {
   var title   = failed_title;
   var text    = failed_text;
  }
  [modal dismiss];
  if (results_box) {
   var alert = [new UIAlertView init];
   [alert setTitle:title];
   [alert setBodyText:text];
   [alert addButtonWithTitle:_("ok")];
   [alert show];
  }
 }
@end
