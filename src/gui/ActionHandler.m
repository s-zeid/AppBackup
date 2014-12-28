/* AppBackup
 * An iOS application that backs up and restores the saved data and
 * preferences of App Store apps.
 * 
 * Copyright (C) 2008-2014 Scott Zeid
 * https://s.zeid.me/projects/appbackup/
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

@implementation ActionHandler {
 UIAlertView *_screen;
 MBProgressHUD *_hud;
 AppListVC *_vc;
}

@synthesize action = _action;
@synthesize chooserTitle = _chooserTitle;
@synthesize chooserPrompt = _chooserPrompt;
@synthesize chooserCancelText = _chooserCancelText;
@synthesize hudDetailsText = _hudDetailsText;
@synthesize stage = _stage;
@synthesize validActions = _validActions;
@synthesize vc = _vc;

- (id)initWithVC:(AppListVC *)vc {
 self = [super init];
 if (self) {
  _vc = [vc retain];
  _validActions = [[NSMutableArray alloc] initWithObjects:
                    @"backup", @"restore", @"ignore", @"unignore",
                    @"delete", nil];
  _chooserCancelText = [[_ s:@"cancel"] copy];
  _stage = AppBackupActionHandlerStageClosed;
 }
 return self;
}

- (void)alertView:(UIAlertView *)alertView
        didDismissWithButtonIndex:(NSInteger)buttonIndex {
 // What to do when you close the backup all apps prompt
 NSString *buttonText = [[alertView buttonTitleAtIndex:buttonIndex] copy];
 _screen = nil;
 if ((self.stage == AppBackupActionHandlerStageChoose &&
      [buttonText isEqualToString:[_ s:@"cancel"]]) ||
     (self.stage == AppBackupActionHandlerStageConfirm &&
      [buttonText isEqualToString:[_ s:@"no"]]) ||
     (self.stage == AppBackupActionHandlerStageResultScreen &&
      [buttonText isEqualToString:[_ s:@"ok"]])) {
  // User canceled action or clicked OK
  _stage = AppBackupActionHandlerStageClosed;
 } else if ([buttonText isEqualToString:[_ s:@"yes"]]) {
  // User confirmed action
  _stage = AppBackupActionHandlerStageInProgress;
  [self doAction];
 } else {
  // User selected action and needs to confirm it first
  _stage = AppBackupActionHandlerStageConfirm;
  int i;
  NSString *t;
  for (i = 0; i < [self.validActions count]; i++) {
   t = [self.validActions objectAtIndex:i];
   if ([buttonText isEqualToString:[_ s:t]]) {
    _action = [t copy];
    break;
   }
  }
  _screen = [[UIAlertView alloc] init];
  _screen.delegate = self;
  _screen.title = [_ s:@"are_you_sure"];
  [_screen addButtonWithTitle:[_ s:@"yes"]];
  NSInteger cancel_btn = [_screen addButtonWithTitle:[_ s:@"no"]];
  [_screen setCancelButtonIndex:cancel_btn];
  [_screen show];
 }
 [buttonText release];
 [alertView release];
 if (_stage == AppBackupActionHandlerStageClosed)
  [self release];
}

- (void)doAction {
 _hud = [[MBProgressHUD alloc] initWithWindow:self.vc.view.window];
 _hud.labelText = [_ s:@"please_wait"];
 _hud.detailsLabelText = self.hudDetailsText;
 [self.vc.view.window addSubview:_hud];
 [_hud showWhileExecuting:@selector(_doActionCallback) onTarget:self
       withObject:nil animated:YES];
 [_hud release];
}

- (void)_doActionCallback {
 [self showResultWithTitle:@"" text:@""];
}

- (void)showResultWithTitle:(NSString *)title text:(NSString *)text {
 [self performSelectorOnMainThread:
        @selector(_showResultWithTitleAndTextCallback:)
       withObject:[NSArray arrayWithObjects:title, text, nil]
       waitUntilDone:YES];
}

- (void)_showResultWithTitleAndTextCallback:(NSArray *)array {
 _stage = AppBackupActionHandlerStageResultScreen;
 _screen = [[UIAlertView alloc] init];
 _screen.title = [array objectAtIndex:0];
 _screen.message = [array objectAtIndex:1];
 [_screen addButtonWithTitle:[_ s:@"ok"]];
 [_screen show];
}

- (void)start {
 _stage = AppBackupActionHandlerStageChoose;
 _screen = [[UIAlertView alloc] init];
 _screen.delegate = self;
 _screen.title = self.chooserTitle;
 _screen.message = self.chooserPrompt;
 int i;
 for (i = 0; i < [self.validActions count]; i++)
  [_screen addButtonWithTitle:[_ s:[self.validActions objectAtIndex:i]]];
 NSInteger cancel_btn = [_screen addButtonWithTitle:self.chooserCancelText];
 [_screen setCancelButtonIndex:cancel_btn];
 [_screen show];
 [self retain];
}

- (void)dealloc {
 self.chooserTitle = nil;
 self.chooserPrompt = nil;
 self.chooserCancelText = nil;
 self.hudDetailsText = nil;
 [_action release];
 [_validActions release];
 [_hud release];
 [_screen release];
 [_vc release];
 [super dealloc];
}
@end
