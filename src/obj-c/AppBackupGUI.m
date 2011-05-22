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

// Main screen

#import <CoreFoundation/CoreFoundation.h>;
#import <UIKit/UIKit.h>;

#import "AppListVC.h";
#import "TestScreenVC.h";
#import "util.h";

#import "AppBackupGUI.h";

@implementation AppBackupGUI
@synthesize window;
@synthesize vc;
@synthesize defaultImageView;
@synthesize shouldShowAppList;
- (void)applicationDidFinishLaunching:(UIApplication *)application {
 // Create the window.  A UIImageView with the Default.png is created because
 // otherwise the user will see an empty window briefly because of the URL
 // handling shit.
 self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
 CGRect bounds = [[UIScreen mainScreen] applicationFrame];
 self.defaultImageView = [[UIView alloc] initWithFrame:bounds];
 UIImage *image = [UIImage imageNamed:@"Default.png"];
 UIImageView *image_view = [[UIImageView alloc] initWithImage:image];
 [defaultImageView addSubview:image_view];
 [image_view release];
 [window addSubview:defaultImageView];
 [window makeKeyAndVisible];
 // Schedule showAppList to be run after application:handleOpenURL: has a
 // chance to run
 self.shouldShowAppList = YES;
 [self performSelector:@selector(showAppList) withObject:nil afterDelay:0.0];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
 if ([[url scheme] isEqualToString:@"appbackup"]) {
  NSString *url_s = [url absoluteString];
  if ([url_s isEqualToString:@"appbackup://test"] ||
      [url_s isEqualToString:@"appbackup://starbucks"] ||
      [url_s isEqualToString:@"appbackup://bnay"] ||
      [url_s isEqualToString:@"appbackup://starbucks/bnay/or/emily"]) {
   self.shouldShowAppList = NO;
   [self performSelector:@selector(showTestScreen) withObject:nil
         afterDelay:0.0];
  }
  return YES;
 }
 return NO;
}

- (void)hideDefaultImageView {
 [defaultImageView removeFromSuperview];
 [defaultImageView release];
 self.defaultImageView = nil;
}

- (void)showAppList {
 // Show app list, if shouldShowAppList is YES
 if (self.shouldShowAppList) {
  self.vc = [[AppListVC alloc] init];
  [window addSubview:vc.view];
  [self hideDefaultImageView];
 }
}

- (void)showTestScreen {
 // Show test screen
 self.vc = [[TestScreenVC alloc] init];
 [window addSubview:vc.view];
 [self hideDefaultImageView];
}

- (void)dealloc {
 self.window = nil;
 self.vc = nil;
 self.defaultImageView = nil;
 self.shouldShowAppList = NO;
 [super dealloc];
}
@end
