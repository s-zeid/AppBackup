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

// App list view controller (header)

#import <CoreFoundation/CoreFoundation.h>;
#import <UIKit/UIKit.h>;

#import "AppBackup.h";
#import "MBProgressHUD.h";

@interface AppListVC : UIViewController
           <UITableViewDataSource, UITableViewDelegate> {
 UITableView *table;
 AppBackup   *appbackup;
 NSString    *app_name;
 NSString    *app_web_site;
 NSString    *about_text;
}
@property (retain) UITableView *table;
@property (retain) AppBackup   *appbackup;
@property (retain) NSString    *app_name;
@property (retain) NSString    *app_web_site;
@property (retain) NSString    *about_text;
- (void)loadView;
- (void)viewDidAppear:(BOOL)animated;
- (NSInteger)numberOfSectionsInTableView:(UITableView *) tv;
- (void)showAboutScreen:(id)sender;
- (void)showAllAppsScreen:(id)sender;
- (void)showBackupOneAppScreenForAppAtIndex:(NSInteger)index;
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s;
- (UITableViewCell *)tableView:(UITableView *)tv
                     cellForRowAtIndexPath:(NSIndexPath *)ip;
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip;
- (UITableViewCell *)tableViewCellWithReuseIdentifier:(NSString *)cell_id;
- (void)updateAppListUsingHUD:(BOOL)useHUD;
- (void)_updateAppListCallback:(MBProgressHUD *)hud;
- (void)updateAppAtIndex:(NSInteger)index;
- (void)updateAppAtIndex:(NSInteger)index withDictionary:(NSDictionary *)dict;
- (void)dealloc;
@end
