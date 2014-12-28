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

// One App action handler

#import <Foundation/Foundation.h>

#import "AppBackup.h"
#import "AppListVC.h"
#import "util.h"

#import "OneAppHandler.h"


@implementation OneAppHandler

@synthesize app = _app;
@synthesize index = _index;

- (id)initWithVC:(AppListVC *)vc appAtIndex:(NSInteger)index {
 self = [super initWithVC:vc];
 if (self) {
  _app = [[vc.appbackup.apps objectAtIndex:index] retain];
  _index = index;
 }
 return self;
}

- (void)doAction {
 NSString *text_ = [_ s:[NSString stringWithFormat:@"1_status_%@_doing",
                         self.action]];
 self.hudDetailsText = [NSString stringWithFormat:text_,
                        [self.app objectForKey:@"friendly"]];
 [super doAction];
}

- (void)_doActionCallback {
 NSString *friendly = [self.app objectForKey:@"friendly"];
 NSString *title;
 NSString *text;
 BOOL      resultsBox  = YES;
 NSDictionary *r = [self.vc.appbackup doAction:self.action onApp:self.app];
 NSDictionary *o = [r objectForKey:@"output"];
 NSDictionary *d = [[o objectForKey:@"normal"] objectAtIndex:0];
 NSNumber     *i = [NSNumber numberWithLong:(long)self.index];
 [self.vc performSelectorOnMainThread:@selector(updateAppAtIndexWithDictUsingArray:)
          withObject:[NSArray arrayWithObjects:i, d, nil] waitUntilDone:YES];
 if ([[r objectForKey:@"success"] boolValue]) {
  title = [_ s:[NSString stringWithFormat:@"%@_done", self.action]];
  text  = [_ s:[NSString stringWithFormat:@"1_status_%@_done", self.action]];
  text  = [_ s:[NSString stringWithFormat:text, friendly]];
  if ([self.action isEqualToString:@"ignore"] ||
      [self.action isEqualToString:@"unignore"])
   resultsBox = NO;
 } else {
  title = [_ s:[NSString stringWithFormat:@"%@_failed", self.action]];
  text  = [_ s:[NSString stringWithFormat:@"1_status_%@_failed", self.action]];
  text  = [_ s:[NSString stringWithFormat:text, friendly]];
 }
 if (resultsBox)
  [self showResultWithTitle:title text:text];
}

- (void)start {
 NSString *prompt = [self.app objectForKey:@"bundle_id"];
 if ([prompt length] > 30)
  prompt = [[prompt substringWithRange:NSMakeRange(0, 30)]
            stringByAppendingString:@"..."];
 prompt = [NSString stringWithFormat:@"(%@)", prompt];
 NSString *cancelString = @"cancel";
 if (![[self.app objectForKey:@"useable"] boolValue]) {
  // App is not useable
  prompt = [NSString stringWithFormat:@"%@\n\n%@", prompt,
            [_ s:@"app_corrupted_prompt"]];
  [self.validActions removeAllObjects]; // No actions possible
  cancelString = [_ s:@"ok"];
 } else if ([[self.app objectForKey:@"ignored"] boolValue]) {
  // App is ignored
  prompt = [NSString stringWithFormat:@"%@\n\n%@", prompt,
            [_ s:@"app_ignored_prompt"]];
  [self.validActions setArray:[NSArray arrayWithObject:@"unignore"]];
 } else if ([[self.app objectForKey:@"backup_time_unix"] doubleValue] != 0.0) {
  // App is backed up
  [self.validActions removeObject:@"unignore"];
 } else {
  // App is not backed up
  [self.validActions setArray:[NSArray arrayWithObjects:@"backup", @"ignore", nil]];
 }
 self.chooserTitle = [self.app objectForKey:@"friendly"];
 self.chooserPrompt = prompt;
 self.chooserCancelText = [_ s:cancelString];
 [super start];
}

- (void)dealloc {
 [_app release];
 [super dealloc];
}
@end
