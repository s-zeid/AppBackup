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

// Test screen view controller

#import <CoreFoundation/CoreFoundation.h>;
#import <UIKit/UIKit.h>;

#import "TestScreenVC.h";
#import "util.h";

@implementation TestScreenVC
@synthesize table;
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
 self.navigationItem.title = @"Starbucks, Bnay, or Emily?";
 // Make table view
 frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
 self.table = [[[UITableView alloc] initWithFrame:frame] autorelease];
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
 static NSString *cellID = @"AppBackupAppCell";
 // Get an existing cell to reuse or make a new one if it doesn't exist yet
 UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:cellID];
 if (cell == nil)
  cell = [self tableViewCellWithReuseIdentifier:cellID];
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

- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)cellID {
 NSInteger width = [self.view bounds].size.width;
 UITableViewCell *cell = [[[UITableViewCell alloc]
                           initWithStyle:UITableViewCellStyleDefault
                           reuseIdentifier:cellID] autorelease];
 UILabel *nameLabel = [[UILabel alloc]
                       initWithFrame:CGRectMake(10, 11, width-20, 25)];
 nameLabel.tag = 1;
 nameLabel.font = [UIFont boldSystemFontOfSize:20];
 nameLabel.adjustsFontSizeToFitWidth = YES;
 nameLabel.textColor = [UIColor blackColor];
 nameLabel.highlightedTextColor = [UIColor whiteColor];
 [cell.contentView addSubview:nameLabel];
 [nameLabel release];
 return cell;
}

- (void)dealloc {
 self.table = nil;
 [super dealloc];
}
@end
