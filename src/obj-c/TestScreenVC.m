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

// Test screen

#import <CoreFoundation/CoreFoundation.h>;
#import <UIKit/UIKit.h>;

#import "TestScreenVC.h";
#import "util.h";

#define NAVBAR_HEIGHT 44

@implementation TestScreenVC
@synthesize table;
- (void)loadView {
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
                                 initWithTitle:@"Starbucks, Bnay, or Emily?"];
 [title_bar pushNavigationItem:title_item animated:NO];
 [title_item release];
 [view addSubview:title_bar];
 [title_bar release];
 // Make table view
 frame = CGRectMake(0, NAVBAR_HEIGHT, bounds.size.width,
                    bounds.size.height - NAVBAR_HEIGHT);
 self.table = [[UITableView alloc] initWithFrame:frame];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *) tv {
 return 1;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
 return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tv
                     cellForRowAtIndexPath:(NSIndexPath *)ip {
 static NSString *cell_id = @"AppBackupAppCell";
 // Get an existing cell to reuse or make a new one if it doesn't exist yet
 UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cell_id];
 if (cell == nil)
  cell = [self tableViewCellWithReuseIdentifier:cell_id];
 // Set up labels
 UILabel *label;
 // Name label
 label = (UILabel *)[cell viewWithTag:1];
 if (ip.row % 3 == 0) label.text = @"STARBUCKS!!!!!111!11!!!one!!1!";
 else if (ip.row % 3 == 1) label.text = @"BNAY!!!1!!one!!one!!11!1!";
 else label.text = @"EMILY!!!!1!!one!!1!";
 // Done!
 return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
 [tv deselectRowAtIndexPath:ip animated:YES];
 UITableViewCell *cell = [tv cellForRowAtIndexPath:ip];
 UIAlertView *alert = [[UIAlertView alloc] init];
 UILabel *label = (UILabel *)[cell viewWithTag:1];
 alert.title = label.text;
 [alert setCancelButtonIndex:[alert addButtonWithTitle:[_ s:@"ok"]]];
 [alert show];
 [alert release];
}

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)cell_id {
 NSInteger width = [self.view bounds].size.width;
 UITableViewCell *cell = [[[UITableViewCell alloc]
                           initWithStyle:UITableViewCellStyleDefault
                           reuseIdentifier:cell_id] autorelease];
 UILabel *name_label = [[UILabel alloc]
                        initWithFrame:CGRectMake(10, 11, width-20, 25)];
 name_label.tag = 1;
 name_label.font = [UIFont boldSystemFontOfSize:20];
 name_label.adjustsFontSizeToFitWidth = YES;
 name_label.textColor = [UIColor blackColor];
 name_label.highlightedTextColor = [UIColor whiteColor];
 [cell.contentView addSubview:name_label];
 [name_label release];
 return cell;
}

- (void)dealloc {
 self.table = nil;
 [super dealloc];
}
@end
