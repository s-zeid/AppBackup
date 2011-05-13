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

#import "util.h";

#import "AboutScreen.h";
#import "AppBackup.h";
#import "BackupAllScreen.h";
#import "BackupOneScreen.h";

#define NAME_TAG 1
#define INFO_TAG 2

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
 self.app_name = [NSBundle.mainBundle
                  objectForInfoDictionaryKey:"CFBundleDisplayName"];
 self.app_web_site = @"http://me.srwz.us/iphone/appbackup";
 self.about_file = bundled_file_path(@"about.txt");
 // Set up window
 self.window = [[UIWindow alloc] initWithFrame:[[UIScreen.mainScreen] bounds]];
 CGRect *bounds = [window bounds];
 self.view = [[UIView alloc] initWithFrame:bounds];
 window.backgroundColor = [UIColor whiteColor];
 window.contentView = view;
 // Make some frames
 CGSize *navbar_size = [UINavigationBar defaultSize];
 CGRect *title_bar_frame = CGRectMake(0, 0, bounds[1][0], navbar_size[1]);
 CGRect *toolbar_frame   = CGRectMake(0, bounds[1][1]-navbar_size[1]+1,
                                      bounds[1][0], navbar_size[1]);
 CGRect *toolbar2_frame  = CGRectMake(0, bounds[1][1]-navbar_size[1],
                                      bounds[1][0], navbar_size[1]);
 CGRect *table_frame     = CGRectMake(0, navbar_size[1], bounds[1][0],
                                      bounds[1][1]-(navbar_size[1]*2));
 // Make the title bar
 UINavigationBar *title_bar = [[UINavigationBar alloc]
                               initWithFrame:title_bar_frame];
 // Make the bottom toolbar and add buttons
 UINavigationBar *toolbar = [[UINavigationBar alloc]
                             initWithFrame:toolbar_frame];
 [toolbar showLeftButton:_(@"all_button") withStyle:0
          showRightButton:_(@"about_button") withStyle:0];
 [toolbar setDelegate:self];
 // Draw a UIToolbar under the bottom toolbar for cosmetic purposes
 UIToolbar *toolbar2 = [[UIToolbar alloc] initWithFrame:toolbar2_frame];
 [view addSubview:title_bar];
 [view addSubview:toolbar2];
 [view addSubview:toolbar];
 [title_bar release]; [toolbar release]; [toolbar2 release];
 // Make table view
 self.table = [[UITableView alloc] initWithFrame:table_frame];
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

- (void)navigationBar:(UINavigationBar *)bar buttonClicked:(NSInteger *)index {
 // About button
 if (button == 0) {
  AboutScreen *screen = [[AboutScreen alloc] initWithGUI:self];
  [screen popupAlertAnimated:YES];
  [screen release];
 }
 // All button
 else {
  BackupAllScreen *screen = [[BackupAllScreen alloc] initWithGUI:self];
  [screen popupAlertAnimated:YES];
  [screen release];
 }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *) tv {
 return 1;
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
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_id];
 if (cell == nil)
  cell = [self tableViewCellWithReuseIdentifier:cell_id];
 // Set up labels
 UILabel *label;
 // Name label
 label = (UILabel *)[cell viewWithTag:NAME_TAG];
 label.text = [app objectForKey:@"friendly"];
 if (![app objectForKey:@"useable"] || [app objectForKey:@"ignored"])
  label.color = [UIColor grayColor];
 // Info label
 label = (UILabel *)[cell viewWithTag:INFO_TAG];
 label.text = [appbackup backupTimeTextForApp:app];
 // Done!
 return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
 [tv deselectRowAtIndexPath:ip animated:YES];
 BackupOneScreen *screen = [[BackupOneScreen] alloc initWithGUI:self
                            appAtIndex:ip.row];
 [screen popupAlertAnimated:YES];
 [screen release];
}

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)cell_id {
 NSInteger width = [[self window] bounds][1][0];
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
 UIProgressHUD *hud = [[UIProgressHud alloc] initWithWindow:window];
 hud.text = _(@"please_wait");
 [hud show:YES];
 [view addSubview:hud];
 [appbackup findApps];
 [table reloadData];
 [hud show:NO];
}

- (void)updateAppAtIndex:(NSInteger *)index {
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
