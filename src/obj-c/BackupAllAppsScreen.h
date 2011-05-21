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

// Backup All Apps screen (header)

#import <UIKit/UIKit.h>;

#import "AppBackup.h";
#import "AppBackupGUI.h";
#import "MBProgressHUD.h";

@interface BackupAllAppsScreen : NSObject
           <MBProgressHUDDelegate, UIAlertViewDelegate> {
 AppBackupGUI        *gui;
 NSString            *action;
 UIAlertView         *action_screen;
 MBProgressHUD       *hud;
 UIAlertView         *result_screen;
}
@property (retain) AppBackupGUI        *gui;
@property (retain) NSString            *action;
@property (retain) UIAlertView         *action_screen;
@property (retain) MBProgressHUD       *hud;
@property (retain) UIAlertView         *result_screen;
- (id)initWithGUI:(AppBackupGUI *)gui_;
+ (id)screenWithGUI:(AppBackupGUI *)gui_;
- (void)alertView:(UIAlertView *)sheet
        didDismissWithButtonIndex:(NSInteger)index;
- (void)doAction;
- (void)hudWasHidden:(MBProgressHUD *)hud;
- (void)show;
- (void)dealloc;
@end
