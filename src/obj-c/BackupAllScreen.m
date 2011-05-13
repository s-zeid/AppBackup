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

// Backup All Apps screen

#import "util.h";
#import "AppBackup.h";
#import "AppBackupGUI.h";

@implementation BackupAllAppsScreen
@synthesize gui;
@synthesize modal;
@synthesize alert;
@synthesize action;

- (id)initWithGUI:(AppBackupGUI *)gui_ {
 self = [super init];
 if (self) {
  self.gui = gui_;
  self.title = _(@"all_apps");
  self.delegate = self;
  NSString *prompt;
  [self addButtonWithTitle:_(@"backup")];
  if ([gui.appbackup.any_backed_up]) {
   prompt = _(@"backup_restore_all_apps");
   [self addButtonWithTitle:_(@"restore")];
   [self addButtonWithTitle:_(@"delete")];
  } else prompt = _(@"backup_all_apps");
  self.bodyText = prompt;
  [self setCancelButtonIndex:[self addButtonWithTitle:_(@"cancel")]];
 }
 return self;
}

- (void)actionSheet:(UIActionSheet *)sheet
        didDismissWithButtonIndex:(NSInteger)index {
 // What to do when you close the backup all apps prompt
 NSString *button_text = [sheet buttonTitleAtIndex:index];
 if ([button_text isEqualToString:_(@"cancel")] ||
     [button_text isEqualToString:_(@"ok")]) return;
 self.modal = [[UIModalView alloc] init];
 modal.title = _(@"please_wait");
 if ([button_text isEqualToString:_(@"backup")])   self.action = @"backup";
 if ([button_text isEqualToString:_(@"delete")])   self.action = @"delete";
 if ([button_text isEqualToString:_(@"ignore")])   self.action = @"ignore";
 if ([button_text isEqualToString:_(@"restore")])  self.action = @"restore";
 if ([button_text isEqualToString:_(@"unignore")]) self.action = @"unignore";
 modal.bodyText = _([NSString stringWithFormat:@"all_status_%s_doing", action]);
 [modal popupAlertAnimated:YES];
 [self doAction];
}

- (void)doAction {
 NSString *done_title     = _([NSString stringWithFormat:@"%s_done", action]);
 NSString *partial_title  = _([NSString stringWithFormat:@"%s_partially_done",
                               action]);
 NSString *done_text      = _([NSString stringWithFormat:@"all_status_%s_done",
                               action]);
 NSString *failed_title   = _([NSString stringWithFormat:@"%s_failed", action]);
 NSString *failed_text    = _([NSString
                               stringWithFormat:@"all_status_%s_failed",
                               action]);
 NSString *corrupted_text = _([NSString
                               stringWithFormat:@"all_status_%s_corrupted",
                               action]);
 NSString *title;
 NSString *text;
 BOOL      results_box  = YES;
 *r = (NSMutableDictionary *)[gui.appbackup doActionOnAllApps:action];
 [gui updateAppList];
 if ([r objectForKey:@"success"]) {
  title = done_title;
  text  = done_text;
  //if ([action isEqualToString:@"ignore"] ||
  //    [action isEqualToString:@"unignore"])
  // results_box = NO;
 } else {
  if ([r objectForKey:@"exit_code"] == 0) title = partially_done_title;
  else                                    title = failed_title;
  text = [NSString stringWithFormat:@"%s\n\n%s", failed_text,
          [r objectForKey:@"data"]];
 }
 [modal dismiss];
 [modal release];
 if (results_box) {
  self.alert = [[UIAlertView alloc] init];
  alert.title = title;
  alert.bodyText = text;
  [alert addButtonWithTitle:_(@"ok")];
  [alert show];
  [alert release];
 }
}

- (void)dealloc {
 self.gui = nil;
 self.modal = nil;
 self.alert = nil;
 self.action = nil;
 [super dealloc];
}
@end
