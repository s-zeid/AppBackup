/* AppBackup
 * An iOS application that backs up and restores the saved data and
 * preferences of App Store apps.
 * 
 * Copyright (C) 2008-2014 Scott Zeid
 * https://s.zeid.me/projects/appbackup/
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

// Error handler class (header)

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>

/**
 */

@interface ErrorHandler : NSObject
           <UIAlertViewDelegate, MFMailComposeViewControllerDelegate> {
 UIViewController *_vc;
 NSString         *_error;
 NSString         *_title;
 NSString         *_text;
 BOOL              _isFatal;
 UIAlertView      *_screen;
 NSCondition      *_dismissedCondition;
 @private
 NSString         *_deadParrot;
 NSInteger         _sendButtonIndex;
 NSInteger         _exitButtonIndex;
 NSInteger         _cancelButtonIndex;
}

/* Properties */

/** The view controller. */
@property (retain, readonly) UIViewController *vc;
/** The actual error; this may be emailed. */
@property (retain, readonly) NSString *error;
/** The title of the alert view. */
@property (retain, readonly) NSString *title;
/** The message text of the alert view; this may be emailed. */
@property (retain, readonly) NSString *text;
/** Whether the error is fatal. */
@property (assign, readonly) BOOL isFatal;

/** The currently active UIAlertView. */
@property (retain) UIAlertView    *screen;

/* Selectors */

/**
 * Initializes the error handler.
 * 
 * @param vc      The view controller to use; may be nil.
 * @param error   The actual error; this may be emailed.
 * @param title   The title of the alert view.
 * @param text    The message text of the alert view; this may be emailed.
 * @param isFatal If YES, the program will exit when the email is sent, or
 *                otherwise not allow the user to continue using the program.
 */
- (id)initWithVC:(UIViewController *)vc
       withError:(NSString *)error withTitle:(NSString *)title
        withText:(NSString *)text isFatal:(BOOL)isFatal;

/**
 * Shows a UIAlertView for the error by sending _showAlertCallback: to
 * the main thread.  
 */
- (void)showAlert;

/**
 * Shows a UIAlertView for the error on the main thread, adds it as a subview
 * to the given window, and makes the window key and visible.
 */
- (void)showAlertWithWindow:(UIWindow *)window;

/** Blocks until the error is dismissed by the user. */
- (void)waitForErrorToBeDismissed;

/**
 * Handles any button press on a UIAlertView.
 * 
 * This may return control to the normal flow or terminate the app, either by
 * opening a mailto: URL in order to email an error report, by calling abort()
 * in the case of a fatal error, or both.
 * 
 * Part of the UIAlertViewDelegate protocol.
 */
- (void)alertView:(UIAlertView *)alertView
        didDismissWithButtonIndex:(NSInteger)buttonIndex;

/**
 * Handles a message being sent.
 * 
 * This will terminate the app if the error is fatal; otherwise, it will just
 * dismiss the MFMailComposeViewController.
 * 
 * Part of the MFMailComposeViewControllerDelegate protocol.
 */
- (void)mailComposeController:(MFMailComposeViewController *)mcvc
        didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error;

- (void)dealloc;

@end
