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
#import "AppListVC.h";
#import "MBProgressHUD.h";
#import "util.h";

#import "BackupAllAppsScreen.h";

@implementation BackupAllAppsScreen
@synthesize vc;
@synthesize action;
@synthesize screen;
@synthesize hud;

- (id)initWithVC:(AppListVC *)vc_ {
 self = [super init];
 if (self) {
  self.vc = vc_;
 }
 return self;
}

- (void)alertView:(UIAlertView *)alertView
        didDismissWithButtonIndex:(NSInteger)buttonIndex {
 // What to do when you close the backup all apps prompt
 NSString *buttonText = [alertView buttonTitleAtIndex:buttonIndex];
 [screen autorelease];
 if ([buttonText isEqualToString:[_ s:@"cancel"]] ||
     [buttonText isEqualToString:[_ s:@"ok"]] ||
     [buttonText isEqualToString:[_ s:@"no"]]) {
  // User canceled action or clicked OK
  [self autorelease];
  return;
 } else if ([buttonText isEqualToString:[_ s:@"yes"]]) {
  // User confirmed action
  [self doAction];
 } else {
  // User selected action and needs to confirm it first
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
  self.screen = [[UIAlertView alloc] init];
  screen.delegate = self;
  screen.title = [_ s:@"are_you_sure"];
  [screen addButtonWithTitle:[_ s:@"yes"]];
  NSInteger cancel_btn = [screen addButtonWithTitle:[_ s:@"no"]];
  [screen setCancelButtonIndex:cancel_btn];
  [screen show];
 }
}

- (void)doAction {
 self.hud = [[MBProgressHUD alloc] initWithWindow:vc.view.window];
 hud.delegate = self;
 hud.yOffset -= vc.navigationController.navigationBar.frame.size.height;
 hud.labelText = [_ s:@"please_wait"];
 hud.detailsLabelText = [_ s:[NSString stringWithFormat:@"all_status_%@_doing",
                                                        action]];
 [vc.view.window addSubview:hud];
 [hud showWhileExecuting:@selector(_doActionCallback) onTarget:self
      withObject:nil animated:YES];
}

- (void)_doActionCallback {
 NSString *title;
 NSString *text;
 BOOL      resultsBox = YES;
 NSDictionary *r = [vc.appbackup doActionOnAllApps:action];
 [vc performSelectorOnMainThread:@selector(updateAppListUsingHUD:)
     withObject:NO waitUntilDone:YES];
 if ([[r objectForKey:@"success"] boolValue]) {
  title = [_ s:[NSString stringWithFormat:@"%@_done", action]];
  text  = [_ s:[NSString stringWithFormat:@"all_status_%@_done", action]];
  //if ([action isEqualToString:@"ignore"] ||
  //    [action isEqualToString:@"unignore"])
  // resultsBox = NO;
 } else {
  if ([r objectForKey:@"exit_code"] == 0)
   title = [_ s:[NSString stringWithFormat:@"%@_partially_done", action]];
  else
   title = [_ s:[NSString stringWithFormat:@"%@_failed",action]];
  text = [_ s:[NSString stringWithFormat:@"all_status_%@_failed", action]];
  text = [NSString stringWithFormat:@"%@\n\n%@",text,[r objectForKey:@"data"]];
 }
 [self performSelectorOnMainThread:@selector(hideHUD) withObject:nil
       waitUntilDone:YES];
 if (resultsBox) {
  [self performSelectorOnMainThread:@selector(showResultWithTitleAndText:)
        withObject:[NSArray arrayWithObjects:title,text,nil] waitUntilDone:YES];
 }
}

- (void)hideHUD {
 [hud hide:YES];
 [hud autorelease];
}

- (void)hudWasHidden:(MBProgressHUD *)hud_ {
 [hud_ removeFromSuperview];
}

- (void)show {
 self.screen = [[UIAlertView alloc] init];
 screen.delegate = self;
 screen.title = [_ s:@"all_apps"];
 NSString *prompt;
 [screen addButtonWithTitle:[_ s:@"backup"]];
 if (vc.appbackup.anyBackedUp) {
  prompt = [_ s:@"backup_restore_all_apps"];
  [screen addButtonWithTitle:[_ s:@"restore"]];
  [screen addButtonWithTitle:[_ s:@"delete"]];
 } else prompt = [_ s:@"backup_all_apps"];
 screen.message = prompt;
 NSInteger cancel_btn = [screen addButtonWithTitle:[_ s:@"cancel"]];
 [screen setCancelButtonIndex:cancel_btn];
 [screen show];
 [self retain];
}

- (void)showResultWithTitleAndText:(NSArray *)array {
 self.screen = [[UIAlertView alloc] init];
 screen.title = [array objectAtIndex:0];
 screen.message = [array objectAtIndex:1];
 [screen addButtonWithTitle:[_ s:@"ok"]];
 [screen show];
}

- (void)dealloc {
 self.vc = nil;
 self.action = nil;
 self.screen = nil;
 self.hud = nil;
 [super dealloc];
}
@end
