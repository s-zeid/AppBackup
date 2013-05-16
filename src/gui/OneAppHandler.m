/* AppBackup
 * An iOS application that backs up and restores the saved data and
 * preferences of App Store apps.
 * 
 * Copyright (C) 2008-2013 Scott Zeid
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

// One App action handler

#import <Foundation/Foundation.h>;

#import "AppBackup.h";
#import "AppListVC.h";
#import "util.h";

#import "OneAppHandler.h";

@implementation OneAppHandler
@synthesize app;
@synthesize index;
- (id)initWithVC:(AppListVC *)vc_ appAtIndex:(NSInteger)index_ {
 self = [super initWithVC:vc_];
 if (self) {
  self.app = [vc.appbackup.apps objectAtIndex:index_];
  self.index = index_;
 }
 return self;
}

- (void)doAction {
 NSString *text_ = [_ s:[NSString stringWithFormat:@"1_status_%@_doing",
                         action]];
 self.hudDetailsText = [NSString stringWithFormat:text_,
                        [app objectForKey:@"friendly"]];
 [super doAction];
}

- (void)_doActionCallback {
 NSString *friendly = [app objectForKey:@"friendly"];
 NSString *title;
 NSString *text;
 BOOL      resultsBox  = YES;
 NSDictionary *r = [vc.appbackup doAction:action onApp:app];
 NSDictionary *d = [[r objectForKey:@"apps"] objectAtIndex:0];
 NSNumber     *i = [NSNumber numberWithInt:index];
 [vc performSelectorOnMainThread:@selector(updateAppAtIndexWithDictUsingArray:)
     withObject:[NSArray arrayWithObjects:i, d, nil] waitUntilDone:YES];
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
 [self hideHUD];
 if (resultsBox)
  [self showResultWithTitle:title text:text];
}

- (void)start {
 NSString *prompt = [app objectForKey:@"bundle"];
 if ([prompt length] > 30)
  prompt = [[prompt substringWithRange:NSMakeRange(0, 30)]
            stringByAppendingString:@"..."];
 prompt = [NSString stringWithFormat:@"(%@)", prompt];
 NSString *cancelString = @"cancel";
 if (![[app objectForKey:@"useable"] boolValue]) {
  // App is not useable
  prompt = [NSString stringWithFormat:@"%@\n\n%@", prompt,
            [_ s:@"app_corrupted_prompt"]];
  [validActions removeAllObjects]; // No actions possible
  cancelString = [_ s:@"ok"];
 } else if ([[app objectForKey:@"ignored"] boolValue]) {
  // App is ignored
  prompt = [NSString stringWithFormat:@"%@\n\n%@", prompt,
            [_ s:@"app_ignored_prompt"]];
  [validActions setArray:[NSArray arrayWithObject:@"unignore"]];
 } else if ([[app objectForKey:@"backup_time"] length]) {
  // App is backed up
  [validActions removeObject:@"unignore"];
 } else {
  // App is not backed up
  [validActions setArray:[NSArray arrayWithObjects:@"backup", @"ignore", nil]];
 }
 self.chooserTitle = [app objectForKey:@"friendly"];
 self.chooserPrompt = prompt;
 self.chooserCancelText = [_ s:cancelString];
 [super start];
}

- (void)dealloc {
 self.app = nil;
 self.index = 0;
 [super dealloc];
}
@end
