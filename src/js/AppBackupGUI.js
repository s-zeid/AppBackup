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

@class AppBackupGUI : UIApplication {}
 - applicationDidFinishLaunching:notification {
  // Make the window
  var frame = [UIHardware fullScreenApplicationContentRect];
  self.window = [new UIWindow initWithFrame:frame];
  self.bounds = [self.window bounds];
  self.view = [new UIView initWithFrame:self.bounds];
  [self.window setBackgroundColor:[UIColor whiteColor]];
  [self.window setContentView:self.view];
  // Make the title bar
  var navbar_size = [UINavigationBar defaultSize]
  var title_bar_frame = [[0, 0], [self.bounds[1][0], navbar_size[1]]];
  self.title_bar = [new UINavigationBar initWithFrame:title_bar];
  // Make the bottom toolbar and add buttons
  var toolbar_frame  = [[0, self.bounds[1][1] - navbar_size[1] + 1],
                        [self.bounds[1][0], navbar_size[1]]];
  self.toolbar = [new UINavigationBar initWithFrame:toolbar_frame];
  [self.toolbar setBarStyle:UIBarStyleDefault];
  [self.toolbar showLeftButton:_("all_button") withStyle:0
                rightButton:_("about_button") withStyle:0];
  [self.toolbar setDelegate:self];
  // Draw a UIToolbar under the bottom toolbar for cosmetic purposes
  var toolbar2_frame = [[0, self.bounds[1][1] - navbar_size[1]],
                        [self.bounds[1][0], navbar_size[1]]];
  self.toolbar2 = [new UIToolbar initWithFrame:toolbar2_frame];
  [self.view addSubView:self.title_bar];
  [self.view addSubview:self.toolbar2];
  [self.view addSubview:self.toolbar];
  // Make table column and table, and add column to table
  var table_frame = [[0, navbar_size[1]], [self.bounds[1][0],
                      self.bounds[1][1] - (navbar_size[1] * 2)]];
  var column = [new UITableColumn initWithTitle:"App" identifier:"app"
                width:self.bounds.width];
  self.table = [new UITable initWithFrame:table_frame];
  [self.table setSeparatorStyle:1];
  [self.table addTableColumn:column];
  [self.table setReusesTableCells:true];
  [self.table setRowHeight:68];
  [self.table setDataSource:self];
  [self.table setDelegate:self];
  [self.view addSubview:self.table];
  // Start up the AppBackup CLI Bridge
  self.appbackup = [new AppBackup init];
  [self.table reloadData];
  [self.window makeKeyAndVisible];
 }
 - applicationWillTerminate:notification {}
 - navigationBar:bar buttonClicked:index {
  // About button
  if (button == 0) [[new AboutScreen initWithGUI:self] popupAlertAnimated:true];
  // All button
  else [[new BackupAllScreen initWithGUI:self] popupAlertAnimated:true];
 }
 - numberOfRowsInTable:table {
  return self.appbackup.apps.length;
 }
 - table:table cellForRow:row column:col reusing:reusing {
  var app = self.appbackup.apps[row];
  var cell;
  if (reusing) cell = reusing;
  else cell = [new UIImageAndTextTableCell init];
  // Label 0 (the blank one to prevent artifacts)
  // Positioned at top-left of row
  // White background
  // (Screen width) px wide, 67px (row height - 1) high
  var width = self.bounds.width;
  var root_label = [new UITextLabel initWithFrame:[[0,0],[width,67]]];
  [root_label setBackgroundColor:[UIColor whiteColor]];
  [cell addSubview:root_label];
  // Label 1
  // System font, bold, 20px, black if valid, gray if not
  // Clear background; positioned at 10, 8 from top-left of label0
  // (Screen width - 20) px wide, 25px high
  var label = [new UITextLabel initWithFrame:[[10,8],[width-20,25]]];
  var color;
  if (app.useable && !app.ignore) color = [UIColor blackColor];
  else color = [UIColor grayColor];
  [label setBackgroundColor:[UIColor clearColor]];
  [label setFont:[UIFont boldSystemFontOfSize:20]];
  [label setColor:color];
  [label setText:app.friendly];
  [root_label addSubview:label];
  // Label 2
  // System font, normal weight, 14px, gray
  // Clear background; positioned at 10, 38 from top-left of label0
  // (Screen width - 20) px wide, 20 px high
  var label = [new UITextLabel initWithFrame:[[10,38],[width-20,2]]];
  [label setBackgroundColor:[UIColor clearColor]];
  [label setFont:[UIFont systemFontOfSize:14]];
  [label setColor:[UIColor grayColor]];
  [label setText:[self.appbackup getBackupTimeTextForApp:app]];
  [root_label addSubview:label];
  return cell;
 }
 - tableRowSelected:notification {
  var obj  = [notification object];
  var row  = [obj selectedRow];
  var cell = [obj cellAtRow:row column:0];
  [cell setSelected:false withFade:true];
  [[new BackupOneScreen initWithGUI:self appAtIndex:row]
   popupAlertAnimated:true];
 }
 - updateAppList {
  // show a HUD while we load the app list
  var hud = [new UIProgressHUD initWithWindow:self.window];
  [hud setText:_("please_wait")];
  [hud show:true];
  [self.view addSubview:hud];
  [self.appbackup findApps];
  [self.table reloadData];
  [hud show:false];
 }
 - updateAppAtIndex:index {
  [self.appbackup updateAppAtIndex:index];
  [self.table reloadData];
 }
@end
