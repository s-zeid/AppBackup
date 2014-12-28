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

// All Apps action handler

#import <Foundation/Foundation.h>

#import "AppBackup.h"
#import "AppListVC.h"
#import "util.h"

#import "AllAppsHandler.h"

@implementation AllAppsHandler
- (id)initWithVC:(AppListVC *)vc {
 self = [super initWithVC:vc];
 if (self) {
  [self.validActions removeObject:@"ignore"];
  [self.validActions removeObject:@"unignore"];
  self.chooserTitle = [_ s:@"all_apps"];
 }
 return self;
}

- (void)doAction {
 self.hudDetailsText = [_ s:[NSString stringWithFormat:@"all_status_%@_doing",
                             self.action]];
 [super doAction];
}

- (void)_doActionCallback {
 NSString *title;
 NSString *text;
 BOOL      resultsBox = YES;
 NSDictionary *r = [self.vc.appbackup doActionOnAllApps:self.action];
 //NSDictionary *o = [r objectForKey:@"output"];
 NSNumber *no = [NSNumber numberWithBool:NO];
 [self.vc performSelectorOnMainThread:@selector(updateAppListUsingHUDFindAppsUsingArray:)
          withObject:[NSArray arrayWithObjects:no, no, nil]
     waitUntilDone:YES];
 if ([[r objectForKey:@"success"] boolValue]) {
  title = [_ s:[NSString stringWithFormat:@"%@_done", self.action]];
  text  = [_ s:[NSString stringWithFormat:@"all_status_%@_done", self.action]];
  //if ([self.action isEqualToString:@"ignore"] ||
  //    [self.action isEqualToString:@"unignore"])
  // resultsBox = NO;
 } else {
  if ([r objectForKey:@"return_code"] == 0)
   title = [_ s:[NSString stringWithFormat:@"%@_partially_done", self.action]];
  else
   title = [_ s:[NSString stringWithFormat:@"%@_failed", self.action]];
  text = [_ s:[NSString stringWithFormat:@"all_status_%@_failed", self.action]];
  text = [NSString stringWithFormat:@"%@\n\n%@",text,[r objectForKey:@"data"]];
 }
 if (resultsBox)
  [self showResultWithTitle:title text:text];
}

- (void)start {
 if (self.vc.appbackup.anyBackedUp)
  self.chooserPrompt = [_ s:@"backup_restore_all_apps"];
 else {
  self.chooserPrompt = [_ s:@"backup_all_apps"];
  [self.validActions removeObject:@"restore"];
  [self.validActions removeObject:@"delete"];
 }
 [super start];
}
@end
