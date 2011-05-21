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

#import <UIKit/UIKit.h>;

#import "AppBackup.h";
#import "AppBackupGUI.h";
#import "MBProgressHUD.h";
#import "util.h";

#import "BackupOneAppScreen.h";

@implementation BackupOneAppScreen
@synthesize gui;
@synthesize index;
@synthesize app;
@synthesize action;
@synthesize action_screen;
@synthesize hud;
@synthesize result_screen;

- (id)initWithGUI:(AppBackupGUI *)gui_ appAtIndex:(NSInteger)index_ {
 self = [super init];
 if (self) {
  self.gui = gui_;
  self.index = index_;
  self.app = [gui.appbackup.apps objectAtIndex:index];
 }
 return self;
}

+ (id)screenWithGUI:(AppBackupGUI *)gui_ appAtIndex:(NSInteger)index_ {
 BackupOneAppScreen *s = [[self alloc] initWithGUI:gui_ appAtIndex:index_];
 return s;
}

- (void)alertView:(UIAlertView *)sheet
        didDismissWithButtonIndex:(NSInteger)button_index {
 // What to do when you close the backup one app prompt
 NSString *button_text = [sheet buttonTitleAtIndex:button_index];
 if ([button_text isEqualToString:[_ s:@"cancel"]] ||
     [button_text isEqualToString:[_ s:@"ok"]]) {
  [self autorelease];
  return;
 }
 if ([button_text isEqualToString:[_ s:@"backup"]])
  self.action = @"backup";
 if ([button_text isEqualToString:[_ s:@"delete"]])
  self.action = @"delete";
 if ([button_text isEqualToString:[_ s:@"ignore"]])
  self.action = @"ignore";
 if ([button_text isEqualToString:[_ s:@"restore"]])
  self.action = @"restore";
 if ([button_text isEqualToString:[_ s:@"unignore"]])
  self.action = @"unignore";
 NSString *text_=[_ s:[NSString stringWithFormat:@"1_status_%@_doing", action]];
 self.hud = [[MBProgressHUD alloc] initWithView:gui.view];
 hud.delegate = self;
 hud.labelText = [_ s:@"please_wait"];
 hud.detailsLabelText = [NSString stringWithFormat:text_,
                         [app objectForKey:@"friendly"]];
 [gui.view addSubview:hud];
 [hud showWhileExecuting:@selector(doAction) onTarget:self withObject:nil
      animated:YES];
}

- (void)doAction {
 NSString *done_title   = [_ s:[NSString stringWithFormat:@"%@_done", action]];
 NSString *done_text_   = [_ s:[NSString stringWithFormat:@"1_status_%@_done",
                             action]];
 NSString *done_text    = [_ s:[NSString stringWithFormat:done_text_,
                             [app objectForKey:@"friendly"]]];
 NSString *failed_title = [_ s:[NSString stringWithFormat:@"%@_failed",action]];
 NSString *failed_text_ = [_ s:[NSString stringWithFormat:@"1_status_%@_failed",
                             action]];
 NSString *failed_text  = [_ s:[NSString stringWithFormat:failed_text_,
                             [app objectForKey:@"friendly"]]];
 NSString *dbg = [_ s:@"starbucks"];
 NSString *title;
 NSString *text;
 BOOL      results_box  = YES;
 NSDictionary *r = [gui.appbackup doAction:action onApp:app];
 dbg = [_ s:@"bnay"];
 [gui updateAppAtIndex:index
      withDictionary:[[r objectForKey:@"apps"] objectAtIndex:0]];
 dbg = [_ s:@"or"];
 if ([[r objectForKey:@"success"] boolValue]) {
  title = done_title;
  text  = done_text;
  if ([action isEqualToString:@"ignore"] ||
      [action isEqualToString:@"unignore"])
   results_box = NO;
 } else {
  title = failed_title;
  text  = failed_text;
 }
 dbg = [_ s:@"Emily"];
 [hud hide:YES];
 [hud release];
 if (results_box) {
  self.result_screen = [[[UIAlertView alloc] init] autorelease];
  result_screen.delegate = self;
  result_screen.title = title;
  result_screen.message = text;
  [result_screen addButtonWithTitle:[_ s:@"ok"]];
  [result_screen show];
 }
}

- (void)hudWasHidden:(MBProgressHUD *)hud_ {
 [hud_ removeFromSuperview];
}

- (void)show {
 self.action_screen = [[UIAlertView alloc] init];
 action_screen.title = [app objectForKey:@"friendly"];
 action_screen.delegate = self;
 NSString *prompt = [app objectForKey:@"bundle"];
 if ([prompt length] > 30)
  prompt = [[prompt substringWithRange:NSMakeRange(0, 30)]
            stringByAppendingString:@"..."];
 prompt = [NSString stringWithFormat:@"(%@)", prompt];
 NSString *cancel_string = @"cancel";
 if (![[app objectForKey:@"useable"] boolValue]) {
  prompt = [NSString stringWithFormat:@"%@\n\n%@", prompt,
            [_ s:@"app_corrupted_prompt"]];
  cancel_string = [_ s:@"ok"];
 } else if ([[app objectForKey:@"ignored"] boolValue]) {
  prompt = [NSString stringWithFormat:@"%@\n\n%@", prompt,
            [_ s:@"app_ignored_prompt"]];
  [action_screen addButtonWithTitle:[_ s:@"unignore"]];
 } else if ([[app objectForKey:@"backup_time"] length]) {
  [action_screen addButtonWithTitle:[_ s:@"backup"]];
  [action_screen addButtonWithTitle:[_ s:@"restore"]];
  [action_screen addButtonWithTitle:[_ s:@"ignore"]];
  [action_screen addButtonWithTitle:[_ s:@"delete"]];
 } else {
  [action_screen addButtonWithTitle:[_ s:@"backup"]];
  [action_screen addButtonWithTitle:[_ s:@"ignore"]];
 }
 action_screen.message = prompt;
 NSInteger cancel_btn = [action_screen addButtonWithTitle:[_ s:cancel_string]];
 [action_screen setCancelButtonIndex:cancel_btn];
 [action_screen show];
}

- (void)dealloc {
 self.gui = nil;
 self.index = 0;
 self.app = nil;
 self.action_screen = nil;
 self.hud = nil;
 self.result_screen = nil;
 [super dealloc];
}
@end
