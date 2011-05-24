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
#import "AppListVC.h";
#import "MBProgressHUD.h";
#import "util.h";

#import "BackupOneAppScreen.h";

@implementation BackupOneAppScreen
@synthesize vc;
@synthesize index;
@synthesize app;
@synthesize action;
@synthesize screen;
@synthesize hud;

- (id)initWithVC:(AppListVC *)vc_ appAtIndex:(NSInteger)index_ {
 self = [super init];
 if (self) {
  self.vc = vc_;
  self.index = index_;
  self.app = [vc.appbackup.apps objectAtIndex:index];
 }
 return self;
}

- (void)alertView:(UIAlertView *)alertView
        didDismissWithButtonIndex:(NSInteger)buttonIndex {
 // What to do when you close the backup one app prompt
 NSString *buttonText = [alertView buttonTitleAtIndex:buttonIndex];
 [screen autorelease];
 if ([buttonText isEqualToString:[_ s:@"cancel"]] ||
     [buttonText isEqualToString:[_ s:@"ok"]]) {
  [self autorelease];
  return;
 }
 if ([buttonText isEqualToString:[_ s:@"backup"]])
  self.action = @"backup";
 if ([buttonText isEqualToString:[_ s:@"delete"]])
  self.action = @"delete";
 if ([buttonText isEqualToString:[_ s:@"ignore"]])
  self.action = @"ignore";
 if ([buttonText isEqualToString:[_ s:@"restore"]])
  self.action = @"restore";
 if ([buttonText isEqualToString:[_ s:@"unignore"]])
  self.action = @"unignore";
 NSString *text_=[_ s:[NSString stringWithFormat:@"1_status_%@_doing", action]];
 self.hud = [[MBProgressHUD alloc] initWithWindow:vc.view.window];
 hud.delegate = self;
 hud.labelText = [_ s:@"please_wait"];
 hud.detailsLabelText = [NSString stringWithFormat:text_,
                         [app objectForKey:@"friendly"]];
 [vc.view.window addSubview:hud];
 [hud showWhileExecuting:@selector(doAction) onTarget:self withObject:nil
      animated:YES];
}

- (void)doAction {
 NSString *friendly = [app objectForKey:@"friendly"];
 NSString *title;
 NSString *text;
 BOOL      resultsBox  = YES;
 NSDictionary *r = [vc.appbackup doAction:action onApp:app];
 [vc updateAppAtIndex:index
      withDictionary:[[r objectForKey:@"apps"] objectAtIndex:0]];
 if ([[r objectForKey:@"success"] boolValue]) {
  title = [_ s:[NSString stringWithFormat:@"%@_done", action]];
  text  = [_ s:[NSString stringWithFormat:@"1_status_%@_done", action]];
  text  = [_ s:[NSString stringWithFormat:text, friendly]];
  if ([action isEqualToString:@"ignore"] ||
      [action isEqualToString:@"unignore"])
   resultsBox = NO;
 } else {
  title = [_ s:[NSString stringWithFormat:@"%@_failed",action]];
  text  = [_ s:[NSString stringWithFormat:@"1_status_%@_failed", action]];
  text  = [_ s:[NSString stringWithFormat:text, friendly]];
 }
 if (resultsBox) {
  self.screen = [[UIAlertView alloc] init];
  screen.delegate = self;
  screen.title = title;
  screen.message = text;
  [screen addButtonWithTitle:[_ s:@"ok"]];
  [hud hide:YES];
  [hud autorelease];
  [screen show];
 } else {
  [hud hide:YES];
  [hud autorelease];
 }
}

- (void)hudWasHidden:(MBProgressHUD *)hud_ {
 [hud_ removeFromSuperview];
}

- (void)show {
 self.screen = [[UIAlertView alloc] init];
 screen.title = [app objectForKey:@"friendly"];
 screen.delegate = self;
 NSString *prompt = [app objectForKey:@"bundle"];
 if ([prompt length] > 30)
  prompt = [[prompt substringWithRange:NSMakeRange(0, 30)]
            stringByAppendingString:@"..."];
 prompt = [NSString stringWithFormat:@"(%@)", prompt];
 NSString *cancelString = @"cancel";
 if (![[app objectForKey:@"useable"] boolValue]) {
  prompt = [NSString stringWithFormat:@"%@\n\n%@", prompt,
            [_ s:@"app_corrupted_prompt"]];
  cancelString = [_ s:@"ok"];
 } else if ([[app objectForKey:@"ignored"] boolValue]) {
  prompt = [NSString stringWithFormat:@"%@\n\n%@", prompt,
            [_ s:@"app_ignored_prompt"]];
  [screen addButtonWithTitle:[_ s:@"unignore"]];
 } else if ([[app objectForKey:@"backup_time"] length]) {
  [screen addButtonWithTitle:[_ s:@"backup"]];
  [screen addButtonWithTitle:[_ s:@"restore"]];
  [screen addButtonWithTitle:[_ s:@"ignore"]];
  [screen addButtonWithTitle:[_ s:@"delete"]];
 } else {
  [screen addButtonWithTitle:[_ s:@"backup"]];
  [screen addButtonWithTitle:[_ s:@"ignore"]];
 }
 screen.message = prompt;
 NSInteger cancelBtn = [screen addButtonWithTitle:[_ s:cancelString]];
 [screen setCancelButtonIndex:cancelBtn];
 [screen show];
 [self retain];
}

- (void)dealloc {
 self.vc = nil;
 self.index = 0;
 self.app = nil;
 self.action = nil;
 self.screen = nil;
 self.hud = nil;
 [super dealloc];
}
@end
