/* AppBackup
 * An iPhoneOS application that backs up and restores the saved data and
 * preferences of App Store apps.
 * 
 * Copyright (C) 2008-2012 Scott Zeid
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

// App delegate

#import <CoreFoundation/CoreFoundation.h>;
#import <UIKit/UIKit.h>;

#import "AppBackup.h";
#import "AppListVC.h";
#import "AboutScreenVC.h";
#import "TestScreenVC.h";
#import "util.h";

#import "AppBackupGUI.h";

@implementation AppBackupGUI
@synthesize window;
@synthesize appbackup;
@synthesize navigationController;
- (void)applicationDidFinishLaunching:(UIApplication *)application {
 // Create the window and navigation controller.
 self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]]
                autorelease];
 // Start up the AppBackup CLI bridge
 self.appbackup = [[[AppBackup alloc] init] autorelease];
 // Set up the navigation and root view controllers
 UIViewController *rootVC = [[AppListVC alloc] initWithAppBackup:appbackup];
 self.navigationController = [[[UINavigationController alloc]
                               initWithRootViewController:rootVC] autorelease];
 [rootVC release];
 [window addSubview:navigationController.view];
 [window makeKeyAndVisible];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)nsurl {
 if ([[nsurl scheme] isEqualToString:@"appbackup"]) {
  NSString *url = [nsurl absoluteString];
  if ([url isEqualToString:@"appbackup://about"])
   [self performSelector:@selector(showAboutScreen) withObject:nil
         afterDelay:0.0];
  if ([url isEqualToString:@"appbackup://test"] ||
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
 [self.appbackup terminateAllRunningTasks];
}

- (void)showAboutScreen {
 // Show about screen
 UIViewController *vc = [[AboutScreenVC alloc] init];
 [self.navigationController pushViewController:vc animated:YES];
 [vc release];
}

- (void)showTestScreen {
 // Show test screen
 UIViewController *vc = [[TestScreenVC alloc] init];
 [self.navigationController pushViewController:vc animated:YES];
 [vc release];
}

- (void)dealloc {
 self.window = nil;
 self.appbackup = nil;
 self.navigationController = nil;
 [super dealloc];
}
@end
