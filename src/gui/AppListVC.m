/* AppBackup
 * An iPhoneOS application that backs up and restores the saved data and
 * preferences of App Store apps.
 * 
 * Copyright (C) 2008-2012 Scott Zeid
 * http://me.srwz.us/projects/appbackup
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

// App list view controller

#import <CoreFoundation/CoreFoundation.h>;
#import <UIKit/UIKit.h>;

#import "AboutScreenVC.h";
#import "AllAppsHandler.h";
#import "AppBackup.h";
#import "OneAppHandler.h";
#import "MBProgressHUD.h";
#import "util.h";

#define NAME_TAG 1
#define INFO_TAG 2

#import "AppListVC.h";

@implementation AppListVC
@synthesize table;
@synthesize appbackup;
@synthesize appsLoaded;
- (id)initWithAppBackup:(AppBackup *)appbackup_ {
 self = [super init];
 if (self) {
  self.appbackup = appbackup_;
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
 self.navigationItem.title = [_ s:@"main_window_title"];
 UIBarButtonItem *back_item = [[UIBarButtonItem alloc]
                               initWithTitle:[_ s:@"apps"]
                               style:UIBarButtonItemStyleBordered
                               target:nil action:nil];
 self.navigationItem.backBarButtonItem = back_item;
 [back_item release];
 // Make the bottom toolbar and add buttons
 frame = CGRectMake(0, bounds.size.height - navBarHeight, bounds.size.width,
                    navBarHeight);
 UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:frame];
 UIBarButtonItem *flexSpace;
 flexSpace = [[UIBarButtonItem alloc]
               initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
               target:nil action:nil];
 UIBarButtonItem *space;
 space = [[UIBarButtonItem alloc]
          initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
          target:nil action:nil];
 space.width = 5;
 UIBarButtonItem *allBtn = [[UIBarButtonItem alloc]
                            initWithTitle:[_ s:@"all_button"]
                            style:UIBarButtonItemStyleBordered
                            target:self action:@selector(startAllAppsHandler:)];
 UIBarButtonItem *aboutBtn = [[UIBarButtonItem alloc]
                              initWithTitle:[_ s:@"about_button"]
                              style:UIBarButtonItemStyleBordered
                              target:self action:@selector(showAboutScreen:)];
 toolbar.items = [NSArray arrayWithObjects:flexSpace, allBtn, space,
                                           aboutBtn, flexSpace, nil];
 [flexSpace release];
 [space release];
 [allBtn release];
 [aboutBtn release];
 [view addSubview:toolbar];
 [toolbar release];
 // Make table view
 frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height - navBarHeight);
 self.table = [[[UITableView alloc] initWithFrame:frame] autorelease];
 table.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
 table.rowHeight = 68;
 table.dataSource = self;
 table.delegate = self;
 [view addSubview:table];
 self.appsLoaded = NO;
}

- (void)viewDidAppear:(BOOL)animated {
 if (!appsLoaded) {
  [table reloadData];
  [self updateAppListUsingHUD:YES];
  self.appsLoaded = YES;
 }
 [super viewDidAppear:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *) tv {
 return 1;
}

- (void)showAboutScreen:(id)sender {
 // Called when you tap the About button
 AboutScreenVC *aboutScreenVC = [[AboutScreenVC alloc] init];
 [self.navigationController pushViewController:aboutScreenVC animated:YES];
 [aboutScreenVC release];
}

- (void)startAllAppsHandler:(id)sender {
 // Called when you tap the All button
 AllAppsHandler *handler = [[AllAppsHandler alloc] initWithVC:self];
 [handler start];
 [handler release];
}

- (void)startOneAppHandlerForAppAtIndex:(NSInteger)index {
 // Called from tableView:didSelectRowAtIndexPath:
 OneAppHandler *handler = [[OneAppHandler alloc] initWithVC:self
                           appAtIndex:index];
 [handler start];
 [handler release];
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
 return [appbackup.apps count];
}

- (UITableViewCell *)tableView:(UITableView *)tv
                     cellForRowAtIndexPath:(NSIndexPath *)ip {
 static NSString *cellID = @"AppBackupAppCell";
 // Get the app
 NSMutableDictionary *app = [appbackup.apps objectAtIndex:ip.row];
 // Get an existing cell to reuse or make a new one if it doesn't exist yet
 UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellID];
 if (cell == nil)
  cell = [self tableViewCellWithReuseIdentifier:cellID];
 // Set up labels
 UILabel *label;
 // Name label
 label = (UILabel *)[cell viewWithTag:NAME_TAG];
 label.text = [app objectForKey:@"friendly"];
 if ([[app objectForKey:@"useable"] boolValue] &&
     ![[app objectForKey:@"ignored"] boolValue])
  label.textColor = [UIColor blackColor];
 else
  label.textColor = [UIColor grayColor];
 // Info label
 label = (UILabel *)[cell viewWithTag:INFO_TAG];
 label.text = [appbackup backupTimeTextForApp:app];
 // Done!
 return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
 // Called when a table row is selected
 [tv deselectRowAtIndexPath:ip animated:YES];
 [self startOneAppHandlerForAppAtIndex:ip.row];
}

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)cellID {
 NSInteger width = [self.view bounds].size.width;
 UITableViewCell *cell = [[[UITableViewCell alloc]
                           initWithStyle:UITableViewCellStyleDefault
                           reuseIdentifier:cellID] autorelease];
 // Label 1 - Name of app
 // System font, bold, text resizes to fit width, 20px, black if valid, gray if
 // not
 // Clear background; positioned at 10, 8 from top-left of label0
 // (Screen width - 20) px wide, 25px high
 UILabel *nameLabel = [[UILabel alloc]
                       initWithFrame:CGRectMake(10, 8, width-20, 25)];
 nameLabel.tag = NAME_TAG;
 nameLabel.font = [UIFont boldSystemFontOfSize:20];
 nameLabel.adjustsFontSizeToFitWidth = YES;
 nameLabel.textColor = [UIColor blackColor];
 nameLabel.highlightedTextColor = [UIColor whiteColor];
 [cell.contentView addSubview:nameLabel];
 [nameLabel release];
 // Label 2
 // System font, normal weight, 14px, gray
 // Clear background; positioned at 10, 38 from top-left of label0
 // (Screen width - 20) px wide, 20 px high
 UILabel *infoLabel = [[UILabel alloc]
                       initWithFrame:CGRectMake(10, 38, width-20, 20)];
 infoLabel.tag = INFO_TAG;
 infoLabel.font = [UIFont systemFontOfSize:14];
 infoLabel.adjustsFontSizeToFitWidth = YES;
 infoLabel.textColor = [UIColor grayColor];
 infoLabel.highlightedTextColor = [UIColor whiteColor];
 [cell.contentView addSubview:infoLabel];
 [infoLabel release];
 return cell;
}

- (void)updateAppListUsingHUD:(BOOL)useHUD {
 if (useHUD) {
  MBProgressHUD *hud = [[MBProgressHUD alloc] initWithWindow:self.view.window];
  [self.view addSubview:hud];
  hud.yOffset -= self.navigationController.navigationBar.frame.size.height*1.5;
  [hud performSelector:@selector(setLabelText:) withObject:[_ s:@"please_wait"]
       afterDelay:0.2];
  [hud showWhileExecuting:@selector(_updateAppListCallback:) onTarget:self
       withObject:hud animated:YES];
  [hud release];
 } else [self _updateAppListCallback:nil];
}

- (void)_updateAppListCallback:(MBProgressHUD *)hud {
 [appbackup findApps];
 [self performSelectorOnMainThread:@selector(updateTableAndRemoveHUD:)
       withObject:hud waitUntilDone:YES];
 
}

- (void)updateAppAtIndex:(NSInteger)index {
 [appbackup updateAppAtIndex:index];
 [self performSelectorOnMainThread:@selector(updateTableAndRemoveHUD:)
       withObject:nil waitUntilDone:YES];
}

- (void)updateAppAtIndex:(NSInteger)index withDictionary:(NSDictionary *)dict {
 [appbackup updateAppAtIndex:index withDictionary:dict];
 [self performSelectorOnMainThread:@selector(updateTableAndRemoveHUD:)
       withObject:nil waitUntilDone:YES];
}

- (void)updateAppAtIndexWithDictUsingArray:(NSArray *)array {
 [self updateAppAtIndex:[[array objectAtIndex:0] integerValue]
       withDictionary:[array objectAtIndex:1]];
}

- (void)updateTableAndRemoveHUD:(MBProgressHUD *)hud {
 [table reloadData];
 if (hud) [hud removeFromSuperview];
}

- (void)dealloc {
 self.table = nil;
 self.appbackup = nil;
 self.appsLoaded = NO;
 [super dealloc];
}
@end
