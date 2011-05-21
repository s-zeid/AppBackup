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

#import <UIKit/UIKit.h>;

#import "AppBackup.h";
#import "AppBackupGUI.h";
#import "util.h";

#import "BackupAllAppsScreen.h";

@implementation BackupAllAppsScreen
@synthesize gui;
@synthesize modal;
@synthesize alert;
@synthesize action;

- (id)initWithGUI:(AppBackupGUI *)gui_ {
 self = [super init];
 if (self) {
  self.gui = gui_;
  self.title = [_ s:@"all_apps"];
  self.delegate = self;
  NSString *prompt;
  [self addButtonWithTitle:[_ s:@"backup"]];
  if (gui.appbackup.any_backed_up) {
   prompt = [_ s:@"backup_restore_all_apps"];
   [self addButtonWithTitle:[_ s:@"restore"]];
   [self addButtonWithTitle:[_ s:@"delete"]];
  } else prompt = [_ s:@"backup_all_apps"];
  self.message = prompt;
  [self setCancelButtonIndex:[self addButtonWithTitle:[_ s:@"cancel"]]];
 }
 return self;
}

- (void)alertView:(UIAlertView *)sheet
        didDismissWithButtonIndex:(NSInteger)index {
 // What to do when you close the backup all apps prompt
 NSString *button_text = [sheet buttonTitleAtIndex:index];
 if ([button_text isEqualToString:[_ s:@"cancel"]] ||
     [button_text isEqualToString:[_ s:@"ok"]]) return;
 self.modal = [[UIAlertView alloc] init];
 modal.title = [_ s:@"please_wait"];
 if ([button_text isEqualToString:[_ s:@"backup"]])   self.action = @"backup";
 if ([button_text isEqualToString:[_ s:@"delete"]])   self.action = @"delete";
 if ([button_text isEqualToString:[_ s:@"ignore"]])   self.action = @"ignore";
 if ([button_text isEqualToString:[_ s:@"restore"]])  self.action = @"restore";
 if ([button_text isEqualToString:[_ s:@"unignore"]]) self.action = @"unignore";
 modal.message=[_ s:[NSString stringWithFormat:@"all_status_%@_doing", action]];
 [modal show];
 [self doAction];
}

- (void)doAction {
 NSString *done_title = [_ s:[NSString stringWithFormat:@"%@_done", action]];
 NSString *partial_title = [_ s:[NSString stringWithFormat:@"%@_partially_done",
                                 action]];
 NSString *done_text = [_ s:[NSString stringWithFormat:@"all_status_%@_done",
                             action]];
 NSString *failed_title = [_ s:[NSString stringWithFormat:@"%@_failed",action]];
 NSString *failed_text = [_ s:[NSString
                               stringWithFormat:@"all_status_%@_failed",
                               action]];
 NSString *corrupted_text = [_ s:[NSString
                                  stringWithFormat:@"all_status_%@_corrupted",
                                  action]];
 NSString *title;
 NSString *text;
 BOOL      results_box  = YES;
 NSDictionary *r = [gui.appbackup doActionOnAllApps:action];
 [gui updateAppList];
 if ([[r objectForKey:@"success"] boolValue]) {
  title = done_title;
  text  = done_text;
  //if ([action isEqualToString:@"ignore"] ||
  //    [action isEqualToString:@"unignore"])
  // results_box = NO;
 } else {
  // TODO: detect all apps corrupted
  if ([r objectForKey:@"exit_code"] == 0) title = partial_title;
  else                                    title = failed_title;
  text = [NSString stringWithFormat:@"%@\n\n%@", failed_text,
          [r objectForKey:@"data"]];
 }
 [modal dismissWithClickedButtonIndex:0 animated:YES];
 [modal release];
 if (results_box) {
  self.alert = [[UIAlertView alloc] init];
  alert.title = title;
  alert.message = text;
  [alert addButtonWithTitle:[_ s:@"ok"]];
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
