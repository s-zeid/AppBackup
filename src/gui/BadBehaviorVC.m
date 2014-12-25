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

// Bad behavior testing screen view controller

#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>

#import "AppBackup.h"
#import "MBProgressHUD.h"
#import "util.h"

#import "BadBehaviorVC.h"


#define  SECTION_SHELL           0
#define   HEADER_SHELL           @"Make the CLI shell..."
#define NUM_ROWS_SHELL           3
#define  ROW_SHELL_FAIL_TO_START 0
#define TEXT_SHELL_FAIL_TO_START @"fail to start"
#define  ROW_SHELL_EXIT          1
#define TEXT_SHELL_EXIT          @"exit while running a command"
#define  ROW_SHELL_TRACEBACK     2
#define TEXT_SHELL_TRACEBACK     @"report a Python traceback"

#define  SECTION_OTHER           1
#define   HEADER_OTHER           @"Other"
#define NUM_ROWS_OTHER           1
#define  ROW_OTHER_STOP_SHELL    0
#define TEXT_OTHER_STOP_SHELL    @"Stop the CLI shell"


@implementation BadBehaviorVC
@synthesize table;
- (id)initWithAppBackup:(AppBackup *)appbackup {
 self = [super init];
 if (self) {
  _appbackup = appbackup;
  _hud       = nil;
 }
 return self;
}
- (void)loadView {
 // Get some frames
 CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
 CGRect navBarFrame = self.navigationController.navigationBar.frame;
 NSInteger navBarHeight = navBarFrame.size.height;
 CGRect bounds = CGRectMake(appFrame.origin.x, appFrame.origin.y,
                            appFrame.size.width,
                            appFrame.size.height - navBarHeight);
 struct CGRect frame;
 // Set up main view
 self.view = [[[UIView alloc] initWithFrame:bounds] autorelease];
 UIView *view = self.view;
 view.backgroundColor = [UIColor whiteColor];
 // Configure the navigation bar
 self.navigationItem.title = @"Bad Behavior";
 // Make table view
 frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
 self.table = [[[UITableView alloc] initWithFrame:frame
                                    style:UITableViewStyleGrouped] autorelease];
 table.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
 table.rowHeight = 48;
 table.dataSource = self;
 table.delegate = self;
 [view addSubview:table];
}

- (void)viewDidAppear:(BOOL)animated {
 [table reloadData];
 [super viewDidAppear:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
 return 2;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s {
 switch (s) {
  case SECTION_SHELL:
   return HEADER_SHELL;
  case SECTION_OTHER:
   return HEADER_OTHER;
  default:
   return @"";
 }
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
 switch (s) {
  case SECTION_SHELL:
   return NUM_ROWS_SHELL;
  case SECTION_OTHER:
   return NUM_ROWS_OTHER;
  default:
   return 0;
 }
}

- (UITableViewCell *)tableView:(UITableView *)tv
                     cellForRowAtIndexPath:(NSIndexPath *)ip {
 static NSString *cellID = @"BadBehaviorCell";
 // Get an existing cell to reuse or make a new one if it doesn't exist yet
 UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellID];
 if (cell == nil)
  cell = [self tableViewCellWithReuseIdentifier:cellID];
 // Set up labels
 UILabel *label;
 // Name label
 label = (UILabel *)[cell viewWithTag:1];
 switch (ip.section) {
  case SECTION_SHELL:
   switch (ip.row) {
    case ROW_SHELL_FAIL_TO_START:
     label.text = TEXT_SHELL_FAIL_TO_START; break;
    case ROW_SHELL_EXIT:
     label.text = TEXT_SHELL_EXIT; break;
    case ROW_SHELL_TRACEBACK:
     label.text = TEXT_SHELL_TRACEBACK; break;
   }
   break;
  case SECTION_OTHER:
   switch (ip.row) {
    case ROW_OTHER_STOP_SHELL:
     label.text = TEXT_OTHER_STOP_SHELL; break;
   }
   break;
 }
 // Done!
 return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
 [tv deselectRowAtIndexPath:ip animated:YES];
 NSString *action = nil;
 switch (ip.section) {
  case SECTION_SHELL:
   switch (ip.row) {
    case ROW_SHELL_FAIL_TO_START:
     action = nil;
     // write "crash at startup" cookie file
     NSString *magicWord = @"please" @"\n";
     [[NSFileManager defaultManager]
      createFileAtPath:CONFIG_ROOT @"/bad-behavior-make-shell-fail-to-start"
      contents:[magicWord dataUsingEncoding:NSUTF8StringEncoding]
      attributes:nil];
     // request restart
     UIAlertView *alert = [[UIAlertView alloc] init];
     alert.title = [NSString stringWithFormat:@"Please restart %@.", PRODUCT_NAME];
     alert.delegate = self;
     [alert setCancelButtonIndex:[alert addButtonWithTitle:[_ s:@"ok"]]];
     [alert show];
     [alert release];
     break;
    case ROW_SHELL_EXIT:
     // run test command
     action = @"exit-while-running-command";
     break;
    case ROW_SHELL_TRACEBACK:
     // run test command
     action = @"report-traceback";
     break;
   }
   break;
  case SECTION_OTHER:
   switch (ip.row) {
    case ROW_OTHER_STOP_SHELL:
     action = nil;
     [self terminateShellAndWaitUntilExit];
     break;
   }
   break;
 }
 if (action != nil)
  [self runBadBehaviorCommandWithArgs:[NSArray arrayWithObjects:action, nil]];
}

- (void)alertView:(UIAlertView *)alertView
        didDismissWithButtonIndex:(NSInteger)buttonIndex {
 abort();
}

- (void)runBadBehaviorCommandWithArgs:(NSArray *)args {
 _hud = [[MBProgressHUD alloc] initWithWindow:self.view.window];
 _hud.delegate = self;
 _hud.labelText = [_ s:@"please_wait"];
 [self.view.window addSubview:_hud];
 [_hud showWhileExecuting:@selector(_runBadBehaviorCommandCallbackWithArgs:)
       onTarget:self withObject:args animated:YES];
}

- (void)_runBadBehaviorCommandCallbackWithArgs:(NSArray *)args {
 [_appbackup runCmd:@"--bad-behavior" withArgs:args];
}

- (void)terminateShellAndWaitUntilExit {
 _hud = [[MBProgressHUD alloc] initWithWindow:self.view.window];
 _hud.delegate = self;
 _hud.labelText = [_ s:@"please_wait"];
 [self.view.window addSubview:_hud];
 [_hud showWhileExecuting:@selector(_terminateShellAndWaitUntilExitCallback)
       onTarget:self withObject:nil animated:YES];
}

- (void)_terminateShellAndWaitUntilExitCallback {
 [_appbackup terminateShellAndWaitUntilExit];
}

- (void)hideHUD {
 [self performSelectorOnMainThread:@selector(_hideHUDCallback) withObject:nil
       waitUntilDone:YES];
}

- (void)_hideHUDCallback {
 [_hud hide:YES];
 [_hud autorelease];
}

- (void)hudWasHidden:(MBProgressHUD *)hud_ {
 [hud_ removeFromSuperview];
}

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)cellID {
 NSInteger width = [self.view bounds].size.width;
 UITableViewCell *cell = [[[UITableViewCell alloc]
                           initWithStyle:UITableViewCellStyleDefault
                           reuseIdentifier:cellID] autorelease];
 UILabel *nameLabel = [[UILabel alloc]
                       initWithFrame:CGRectMake(10, 11, width-40, 25)];
 nameLabel.tag = 1;
 nameLabel.font = [UIFont boldSystemFontOfSize:18];
 nameLabel.adjustsFontSizeToFitWidth = YES;
 nameLabel.textColor = [UIColor blackColor];
 nameLabel.highlightedTextColor = [UIColor whiteColor];
 [cell.contentView addSubview:nameLabel];
 [nameLabel release];
 return cell;
}

- (void)dealloc {
 self.table = nil;
 _appbackup = nil;
 _hud = nil;
 [super dealloc];
}
@end
