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

// App delegate

#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>

#import "AppBackup.h"
#import "AppListVC.h"
#import "AboutScreenVC.h"
#import "BadBehaviorVC.h"
#import "ErrorHandler.h"
#import "TestScreenVC.h"
#import "util.h"

#import "AppBackupGUI.h"


@implementation AppBackupGUI {
 @private
 UINavigationController *_navigationController;
}

@synthesize window = _window;
@synthesize appbackup = _appbackup;

- (UIWindow *)window {
 // iOS 5+ wants this:
 // <https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIApplicationDelegate_Protocol/#//apple_ref/occ/intfp/UIApplicationDelegate/window>
 if (_window == nil)
  _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
 return _window;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
 // Set up the window and navigation controller
 UIViewController *tmpVC = [[UIViewController alloc] init];
 [self.window addSubview:tmpVC.view];
 // Start up the AppBackup CLI bridge
 _appbackup = [[AppBackup alloc] initWithVC:tmpVC];
 if (self.appbackup.shellReturned == nil) {
  // Set up the navigation and root view controllers
  UIViewController *appListVC = [[AppListVC alloc] initWithAppBackup:self.appbackup];
  _navigationController = [[UINavigationController alloc]
                           initWithRootViewController:appListVC];
  [appListVC release];
  self.appbackup.vc = _navigationController;
  [tmpVC.view removeFromSuperview];
  [self.window addSubview:_navigationController.view];
  [self.window makeKeyAndVisible];
  [_navigationController viewDidAppear:NO];
 }
 [tmpVC release];
 // AppBackup's initWithVC: will set up the window if it doesn't start
 // properly.
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)nsurl {
 if ([[nsurl scheme] isEqualToString:@"appbackup"]) {
  NSString *url = [nsurl absoluteString];
  NSLog(@"launched by URL \"%@\"", url);
  if ([url isEqualToString:@"appbackup://about"])
   [self performSelector:@selector(showAboutScreen) withObject:nil
         afterDelay:0.0];
  else if ([url isEqualToString:@"appbackup://bad-behavior"]) {
   [self performSelector:@selector(showBadBehaviorScreen) withObject:nil
         afterDelay:0.0];
  } else if ([url isEqualToString:@"appbackup://test"] ||
             [url isEqualToString:@"appbackup://starbucks"] ||
             [url isEqualToString:@"appbackup://bnay"] ||
             [url isEqualToString:@"appbackup://starbucks/bnay/or/emily"]) {
   [self performSelector:@selector(showTestScreen) withObject:nil
         afterDelay:0.0];
  }
  return YES;
 }
 return NO;
}

- (void)applicationWillTerminate:(UIApplication *)application {
 [self.appbackup terminateShell];
}

- (void)showAboutScreen {
 // Show about screen
 NSLog(@"showing about screen");
 UIViewController *vc = [[AboutScreenVC alloc] init];
 [_navigationController pushViewController:vc animated:YES];
 [vc release];
}

- (void)showBadBehaviorScreen {
 // Show bad behavior testing screen
 NSLog(@"showing bad behavior screen");
 UIViewController *vc = [[BadBehaviorVC alloc] initWithAppBackup:self.appbackup];
 [_navigationController pushViewController:vc animated:YES];
 [vc release];
}

- (void)showTestScreen {
 NSLog(@"showing test screen");
 // Show test screen
 UIViewController *vc = [[TestScreenVC alloc] init];
 [_navigationController pushViewController:vc animated:YES];
 [vc release];
}

- (void)dealloc {
 [_window release];
 [_appbackup release];
 [_navigationController release];
 [super dealloc];
}
@end
