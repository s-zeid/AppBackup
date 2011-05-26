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

// Action handler base class (header)

#import <UIKit/UIKit.h>;

#import "AppListVC.h";
#import "MBProgressHUD.h";

@interface ActionHandler : NSObject
           <MBProgressHUDDelegate, UIAlertViewDelegate> {
 NSString       *action;
 NSString       *chooserTitle;
 NSString       *chooserPrompt;
 NSString       *chooserCancelText;
 NSString       *hudDetailsText;
 MBProgressHUD  *hud;
 UIAlertView    *screen;
 NSMutableArray *validActions;
 AppListVC      *vc;
}
@property (retain) NSString       *action;
@property (retain) NSString       *chooserTitle;
@property (retain) NSString       *chooserPrompt;
@property (retain) NSString       *chooserCancelText;
@property (retain) MBProgressHUD  *hud;
@property (retain) NSString       *hudDetailsText;
@property (retain) UIAlertView    *screen;
@property (retain) NSMutableArray *validActions;
@property (retain) AppListVC      *vc;
- (id)initWithVC:(AppListVC *)vc_;
- (void)alertView:(UIAlertView *)alertView
        didDismissWithButtonIndex:(NSInteger)buttonIndex;
- (void)doAction;
- (void)_doActionCallback;
- (void)hideHUD;
- (void)_hideHUDCallback;
- (void)hudWasHidden:(MBProgressHUD *)hud;
- (void)showResultWithTitle:(NSString *)title text:(NSString *)text;
- (void)start;
- (void)_showResultWithTitleAndTextCallback:(NSArray *)array;
- (void)dealloc;
@end
