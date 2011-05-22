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

// About screen

#import <UIKit/UIKit.h>;

#import "AppBackupGUI.h";
#import "util.h";

#import "AboutScreen.h";

@implementation AboutScreen
@synthesize gui;
@synthesize screen;
- (id)initWithGUI:(AppBackupGUI *)gui_ {
 self = [super init];
 if (self) {
  self.gui = gui_;
 }
 return self;
}

- (void)alertView:(UIAlertView *)sheet
        didDismissWithButtonIndex:(NSInteger)index {
 NSString *action = [sheet buttonTitleAtIndex:index];
 if ([action isEqualToString:[_ s:@"web_site"]]) {
  NSURL *url = [NSURL URLWithString:gui.app_web_site];
  [[UIApplication sharedApplication] openURL:url];
  [url release];
  [self autorelease];
 }
}

- (void)show {
 screen.title = [NSString stringWithFormat:[_ s:@"about_title"], gui.app_name];
 screen.delegate = self;
 screen.message = gui.about_text;
 [screen addButtonWithTitle:[_ s:@"web_site"]];
 [screen setCancelButtonIndex:[screen addButtonWithTitle:[_ s:@"ok"]]];
 [self retain];
}

- (void)dealloc {
 self.gui = nil;
 [super dealloc];
}
@end
