/* AppBackup
 * An iOS application that backs up and restores the saved data and
 * preferences of App Store apps.
 * 
 * Copyright (C) 2008-2014 Scott Zeid
 * http://s.zeid.me/projects/appbackup/
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

// Action handler base class

#import <UIKit/UIKit.h>

#import "AppBackup.h"
#import "AppListVC.h"
#import "MBProgressHUD.h"
#import "util.h"

#import "ActionHandler.h"

@implementation ActionHandler
@synthesize action;
@synthesize chooserTitle;
@synthesize chooserPrompt;
@synthesize chooserCancelText;
@synthesize hud;
@synthesize hudDetailsText;
@synthesize screen;
@synthesize stage;
@synthesize validActions;
@synthesize vc;

- (id)initWithVC:(AppListVC *)vc_ {
 self = [super init];
 if (self) {
  self.vc = vc_;
  self.validActions = [NSMutableArray arrayWithObjects:
                        @"backup", @"restore", @"ignore", @"unignore",
                        @"delete", nil];
  self.chooserCancelText = [_ s:@"cancel"];
  self.stage = AppBackupActionHandlerStageClosed;
 }
 return self;
}

- (void)alertView:(UIAlertView *)alertView
        didDismissWithButtonIndex:(NSInteger)buttonIndex {
 // What to do when you close the backup all apps prompt
 NSString *buttonText = [alertView buttonTitleAtIndex:buttonIndex];
 [screen autorelease];
 if ((stage == AppBackupActionHandlerStageChoose &&
      [buttonText isEqualToString:[_ s:@"cancel"]]) ||
     (stage == AppBackupActionHandlerStageConfirm &&
      [buttonText isEqualToString:[_ s:@"no"]]) ||
     (stage == AppBackupActionHandlerStageResultScreen &&
      [buttonText isEqualToString:[_ s:@"ok"]])) {
  // User canceled action or clicked OK
  self.stage = AppBackupActionHandlerStageClosed;
  [self autorelease];
  return;
 } else if ([buttonText isEqualToString:[_ s:@"yes"]]) {
  // User confirmed action
  self.stage = AppBackupActionHandlerStageInProgress;
  [self doAction];
 } else {
  // User selected action and needs to confirm it first
  self.stage = AppBackupActionHandlerStageConfirm;
  int i;
  NSString *t;
  for (i = 0; i < [validActions count]; i++) {
   t = [validActions objectAtIndex:i];
   if ([buttonText isEqualToString:[_ s:t]]) {
    self.action = t;
    break;
   }
  }
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
 hud.labelText = [_ s:@"please_wait"];
 hud.detailsLabelText = hudDetailsText;
 [vc.view.window addSubview:hud];
 [hud showWhileExecuting:@selector(_doActionCallback) onTarget:self
      withObject:nil animated:YES];
}

- (void)_doActionCallback {
 [self showResultWithTitle:@"" text:@""];
}

- (void)hideHUD {
 [self performSelectorOnMainThread:@selector(_hideHUDCallback) withObject:nil
       waitUntilDone:YES];
}

- (void)_hideHUDCallback {
 [hud hide:YES];
 [hud autorelease];
}

- (void)hudWasHidden:(MBProgressHUD *)hud_ {
 [hud_ removeFromSuperview];
}

- (void)showResultWithTitle:(NSString *)title text:(NSString *)text {
 [self performSelectorOnMainThread:
        @selector(_showResultWithTitleAndTextCallback:)
       withObject:[NSArray arrayWithObjects:title, text, nil]
       waitUntilDone:YES];
}

- (void)_showResultWithTitleAndTextCallback:(NSArray *)array {
 self.stage = AppBackupActionHandlerStageResultScreen;
 self.screen = [[UIAlertView alloc] init];
 screen.title = [array objectAtIndex:0];
 screen.message = [array objectAtIndex:1];
 [screen addButtonWithTitle:[_ s:@"ok"]];
 [screen show];
}

- (void)start {
 self.stage = AppBackupActionHandlerStageChoose;
 self.screen = [[UIAlertView alloc] init];
 screen.delegate = self;
 screen.title = chooserTitle;
 screen.message = chooserPrompt;
 int i;
 for (i = 0; i < [validActions count]; i++)
  [screen addButtonWithTitle:[_ s:[validActions objectAtIndex:i]]];
 NSInteger cancel_btn = [screen addButtonWithTitle:chooserCancelText];
 [screen setCancelButtonIndex:cancel_btn];
 [screen show];
 [self retain];
}

- (void)dealloc {
 self.action = nil;
 self.chooserTitle = nil;
 self.chooserPrompt = nil;
 self.chooserCancelText = nil;
 self.hud = nil;
 self.hudDetailsText = nil;
 self.screen = nil;
 self.validActions = nil;
 self.vc = nil;
 [super dealloc];
}
@end
