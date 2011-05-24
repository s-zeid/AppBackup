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

// App list view controller

#import <CoreFoundation/CoreFoundation.h>;
#import <UIKit/UIKit.h>;

#import "AboutScreen.h";
#import "AppBackup.h";
#import "BackupAllAppsScreen.h";
#import "BackupOneAppScreen.h";
#import "MBProgressHUD.h";
#import "util.h";

#define NAVBAR_HEIGHT 44
#define NAME_TAG 1
#define INFO_TAG 2

#import "AppListVC.h";

@implementation AppListVC
@synthesize table;
@synthesize appbackup;
@synthesize app_name;
@synthesize app_web_site;
@synthesize about_text;
- (void)loadView {
 // Set some properties
 self.app_name = [[NSBundle mainBundle]
                  objectForInfoDictionaryKey:@"CFBundleDisplayName"];
 self.app_web_site = @"http://me.srwz.us/iphone/appbackup";
 self.about_text = [NSString
                    stringWithContentsOfFile:[_ bundledFilePath:@"about.txt"]
                    encoding:NSUTF8StringEncoding error:nil];
 // Set up window
 CGRect bounds = [[UIScreen mainScreen] applicationFrame];
 self.view = [[UIView alloc] initWithFrame:bounds];
 UIView *view = self.view;
 view.backgroundColor = [UIColor whiteColor];
 // Make some frames
 struct CGRect frame;
 // Make the title bar
 frame = CGRectMake(0, 0, bounds.size.width, NAVBAR_HEIGHT);
 UINavigationBar *title_bar = [[UINavigationBar alloc] initWithFrame:frame];
 UINavigationItem *title_item = [[UINavigationItem alloc]
                                 initWithTitle:[_ s:@"main_window_title"]];
 UIBarButtonItem *back_item = [[UIBarButtonItem alloc]
                               initWithTitle:[_ s:@"apps"]
                               style:UIBarButtonItemStyleBordered
                               target:nil action:nil];
 title_item.backBarButtonItem = back_item;
 [back_item release];
 [title_bar pushNavigationItem:title_item animated:NO];
 [title_item release];
 [view addSubview:title_bar];
 [title_bar release];
 // Make the bottom toolbar and add buttons
 frame = CGRectMake(0, bounds.size.height - NAVBAR_HEIGHT, bounds.size.width,
                    NAVBAR_HEIGHT);
 UINavigationBar *toolbar = [[UIToolbar alloc] initWithFrame:frame];
 toolbar.delegate = self;
 UIBarButtonItem *flex_space;
 flex_space = [[UIBarButtonItem alloc]
               initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
               target:nil action:nil];
 UIBarButtonItem *space;
 space = [[UIBarButtonItem alloc]
          initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
          target:nil action:nil];
 space.width = 5;
 UIBarButtonItem *all_btn = [[UIBarButtonItem alloc]
                             initWithTitle:[_ s:@"all_button"]
                             style:UIBarButtonItemStyleBordered
                             target:self action:@selector(showAllAppsScreen:)];
 UIBarButtonItem *about_btn = [[UIBarButtonItem alloc]
                               initWithTitle:[_ s:@"about_button"]
                               style:UIBarButtonItemStyleBordered
                               target:self action:@selector(showAboutScreen:)];
 toolbar.items = [NSArray arrayWithObjects:flex_space, all_btn, space,
                                           about_btn, flex_space, nil];
 [flex_space release];
 [space release];
 [all_btn release];
 [about_btn release];
 [view addSubview:toolbar];
 [toolbar release];
 // Make table view
 frame = CGRectMake(0, NAVBAR_HEIGHT, bounds.size.width,
                    bounds.size.height - (NAVBAR_HEIGHT * 2));
 UITableView *_table = [[UITableView alloc] initWithFrame:frame];
 self.table = _table;
 [_table release];
 table.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
 table.rowHeight = 68;
 table.dataSource = self;
 table.delegate = self;
 [view addSubview:table];
 // Start up the AppBackup CLI bridge
 self.appbackup = [[AppBackup alloc] init];
}

- (void)viewDidAppear:(BOOL)animated {
 [table reloadData];
 [self updateAppListUsingHUD:YES];
 [super viewDidAppear:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *) tv {
 return 1;
}

- (void)showAboutScreen:(id)sender {
 // Called when you tap the About button
 AboutScreen *screen = [[AboutScreen alloc] initWithVC:self];
 [screen show];
 [screen release];
}

- (void)showAllAppsScreen:(id)sender {
 // Called when you tap the All button
 BackupAllAppsScreen *screen = [[BackupAllAppsScreen alloc] initWithVC:self];
 [screen show];
 [screen release];
}

- (void)showBackupOneAppScreenForAppAtIndex:(NSInteger)index {
 // Called from tableView:didSelectRowAtIndexPath:
 BackupOneAppScreen *screen = [[BackupOneAppScreen alloc] initWithVC:self
                               appAtIndex:index];
 [screen show];
 [screen release];
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
 return [appbackup.apps count];
}

- (UITableViewCell *)tableView:(UITableView *)tv
                     cellForRowAtIndexPath:(NSIndexPath *)ip {
 static NSString *cell_id = @"AppBackupAppCell";
 // Get the app
 NSMutableDictionary *app = [appbackup.apps objectAtIndex:ip.row];
 // Get an existing cell to reuse or make a new one if it doesn't exist yet
 UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cell_id];
 if (cell == nil)
  cell = [self tableViewCellWithReuseIdentifier:cell_id];
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
 [self showBackupOneAppScreenForAppAtIndex:ip.row];
}

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)cell_id {
 NSInteger width = [self.view bounds].size.width;
 UITableViewCell *cell = [[[UITableViewCell alloc]
                           initWithStyle:UITableViewCellStyleDefault
                           reuseIdentifier:cell_id] autorelease];
 // Label 1 - Name of app
 // System font, bold, text resizes to fit width, 20px, black if valid, gray if
 // not
 // Clear background; positioned at 10, 8 from top-left of label0
 // (Screen width - 20) px wide, 25px high
 UILabel *name_label = [[UILabel alloc]
                        initWithFrame:CGRectMake(10, 8, width-20, 25)];
 name_label.tag = NAME_TAG;
 name_label.font = [UIFont boldSystemFontOfSize:20];
 name_label.adjustsFontSizeToFitWidth = YES;
 name_label.textColor = [UIColor blackColor];
 name_label.highlightedTextColor = [UIColor whiteColor];
 [cell.contentView addSubview:name_label];
 [name_label release];
 // Label 2
 // System font, normal weight, 14px, gray
 // Clear background; positioned at 10, 38 from top-left of label0
 // (Screen width - 20) px wide, 20 px high
 UILabel *info_label = [[UILabel alloc]
                        initWithFrame:CGRectMake(10, 38, width-20, 20)];
 info_label.tag = INFO_TAG;
 info_label.font = [UIFont systemFontOfSize:14];
 info_label.adjustsFontSizeToFitWidth = YES;
 info_label.textColor = [UIColor grayColor];
 info_label.highlightedTextColor = [UIColor whiteColor];
 [cell.contentView addSubview:info_label];
 [info_label release];
 return cell;
}

- (void)updateAppListUsingHUD:(BOOL)useHUD {
 if (useHUD) {
  MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
  hud.labelText = [_ s:@"please_wait"];
  [self.view addSubview:hud];
  [hud showWhileExecuting:@selector(_updateAppListCallback:) onTarget:self
       withObject:hud animated:YES];
  [hud release];
 } else [self _updateAppListCallback:nil];
}

- (void)_updateAppListCallback:(MBProgressHUD *)hud {
 [appbackup findApps];
 [table reloadData];
 if (hud) [hud removeFromSuperview];
}

- (void)updateAppAtIndex:(NSInteger)index {
 [appbackup updateAppAtIndex:index];
 [table reloadData];
}

- (void)updateAppAtIndex:(NSInteger)index withDictionary:(NSDictionary *)dict {
 [appbackup updateAppAtIndex:index withDictionary:dict];
 [table reloadData];
}

- (void)dealloc {
 self.table = nil;
 self.appbackup = nil;
 self.app_name = nil;
 self.app_web_site = nil;
 self.about_text = nil;
 [super dealloc];
}
@end
