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

#import "AboutScreen.h";
#import "AppBackup.h";
#import "BackupAllAppsScreen.h";
#import "BackupOneAppScreen.h";
#import "MBProgressHUD.h";
#import "util.h";

#define NAVBAR_HEIGHT 44
#define NAME_TAG 1
#define INFO_TAG 2

#import "AppBackupGUI.h";

@implementation AppBackupGUI
@synthesize window;
@synthesize view;
@synthesize table;
@synthesize appbackup;
@synthesize app_name;
@synthesize app_web_site;
@synthesize about_file;
- (void)applicationDidFinishLaunching:(UIApplication *)application {
 // Set some properties
 self.app_name = [[NSBundle mainBundle]
                  objectForInfoDictionaryKey:@"CFBundleDisplayName"];
 self.app_web_site = @"http://me.srwz.us/iphone/appbackup";
 self.about_file = [_ bundledFilePath:@"about.txt"];
 // Set up window
 self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
 CGRect bounds = window.bounds;
 self.view = [[UIView alloc] initWithFrame:bounds];
 window.backgroundColor = [UIColor whiteColor];
 [window addSubview:view];
 // Make some frames
 struct CGRect frame;
 // Make the title bar
 frame = CGRectMake(0, 0, bounds.size.width, NAVBAR_HEIGHT);
 UINavigationBar *title_bar = [[UINavigationBar alloc] initWithFrame:frame];
 [view addSubview:title_bar];
 [title_bar release];
 // Make the bottom toolbar and add buttons
 frame = CGRectMake(0, bounds.size.height - NAVBAR_HEIGHT, bounds.size.width,
                    NAVBAR_HEIGHT);
 UINavigationBar *toolbar = [[UIToolbar alloc] initWithFrame:frame];
 toolbar.delegate = self;
 UIBarButtonItem *all_btn = [[UIBarButtonItem alloc]
                             initWithTitle:[_ s:@"all_button"]
                             style:UIBarButtonItemStyleBordered
                             target:self action:@selector(showAllAppsScreen:)];
 UIBarButtonItem *about_btn = [[UIBarButtonItem alloc]
                               initWithTitle:[_ s:@"about_button"]
                               style:UIBarButtonItemStyleBordered
                               target:self action:@selector(showAboutScreen:)];
 toolbar.items = [NSArray arrayWithObjects:all_btn, about_btn];
 [all_btn release];
 [about_btn release];
 [view addSubview:toolbar];
 [toolbar release];
 // Make table view
 frame = CGRectMake(0, NAVBAR_HEIGHT, bounds.size.width,
                    bounds.size.height - (NAVBAR_HEIGHT * 2));
 self.table = [[UITableView alloc] initWithFrame:frame];
 table.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
 table.rowHeight = 68;
 table.dataSource = self;
 table.delegate = self;
 [view addSubview:table];
 // Start up the AppBackup CLI bridge
 self.appbackup = [[[AppBackup alloc] init] retain];
 [window makeKeyAndVisible];
 // TODO: move this into a thread
 [table reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *) tv {
 return 1;
}

- (void)showAboutScreen:(id)sender {
 // Called when you tap the About button
 AboutScreen *screen = [[AboutScreen alloc] initWithGUI:self];
 [screen show];
 [screen release];
}

- (void)showAllAppsScreen:(id)sender {
 // Called when you tap the All button
 BackupAllAppsScreen *screen = [[BackupAllAppsScreen alloc] initWithGUI:self];
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
 if (![app objectForKey:@"useable"] || [app objectForKey:@"ignored"])
  label.textColor = [UIColor grayColor];
 // Info label
 label = (UILabel *)[cell viewWithTag:INFO_TAG];
 label.text = [appbackup backupTimeTextForApp:app];
 // Done!
 return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
 [tv deselectRowAtIndexPath:ip animated:YES];
 BackupOneAppScreen *screen = [[BackupOneAppScreen alloc] initWithGUI:self
                               appAtIndex:ip.row];
 [screen show];
 [screen release];
}

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)cell_id {
 NSInteger width = [[self window] bounds].size.width;
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

- (void)updateAppList {
 MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:view];
 hud.labelText = [_ s:@"please_wait"];
 [view addSubview:hud];
 [hud showWhileExecuting:@selector(_updateAppListCallback) onTarget:self
      withObject:nil animated:YES];
 [hud release];
}

- (void)_updateAppListCallback {
 [appbackup findApps];
 [table reloadData];
}

- (void)updateAppAtIndex:(NSInteger)index {
 [appbackup updateAppAtIndex:index];
 [table reloadData];
}

- (void)dealloc {
 self.window = nil;
 self.view = nil;
 self.table = nil;
 self.appbackup = nil;
 self.app_name = nil;
 self.app_web_site = nil;
 self.about_file = nil;
 [super dealloc];
}
@end
