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

/**
 * ActionHandler is an abstract base class for handling the case where the user
 * wants to perform an action on one or more apps on their iDevice.  A valid
 * action is one of backup, delete, ignore, unignore, and restore.  Subclasses
 * are responsible for determining how many and which apps need to be acted
 * upon, whether the apps can be acted upon, and whether the apps are ignored,
 * and then act accordingly.
 * 
 * All subclasses must override the selectors doAction, _doActionCallback, and
 * start in their implementations.  doAction and start must call super at the
 * end of their implementations.
 * 
 * The properties chooserTitle and chooserPrompt must be defined before
 * -[super start] is sent.  action is set after the user chooses an action.
 * hudDetailsText must be set before -[super doAction] is sent.
 * 
 * validActions is an array of possible actions.  It defaults to containing all
 * possible actions, but you must change it before sending -[super start], as
 * you must determine in your subclass which actions are possible.
 */

@interface ActionHandler : NSObject
           <MBProgressHUDDelegate, UIAlertViewDelegate> {
 NSString       *action;
 NSString       *chooserTitle;
 NSString       *chooserPrompt;
 NSString       *chooserCancelText;
 MBProgressHUD  *hud;
 NSString       *hudDetailsText;
 UIAlertView    *screen;
 NSMutableArray *validActions;
 AppListVC      *vc;
}

/* Properties */

/** The action to perform (backup, delete, ignore, unignore, restore). */
@property (retain) NSString       *action;

/**
 * The title text to use for the action chooser UIAlertView.  Must be set
 * before -[super start] is sent.
 */
@property (retain) NSString       *chooserTitle;

/**
 * The prompt text to use for the chooser (translates to the message property
 * of UIAlertView).  Must be set before -[super start] is sent.
 */
@property (retain) NSString       *chooserPrompt;

/**
 * The text to use for the chooser's cancel button.  Defaults to
 * [_ s:@"cancel"].
 */
@property (retain) NSString       *chooserCancelText;

/** The progress HUD shown while the action is being performed. */
@property (retain) MBProgressHUD  *hud;

/**
 * The details text to use for the progress HUD.  Must be set before
 * -[super doAction] is sent.
 */
@property (retain) NSString       *hudDetailsText;

/** The currently active UIAlertView. */
@property (retain) UIAlertView    *screen;

/**
 * A list of valid actions for this instance in the order you want them to
 * appear.  Defaults to containing backup, restore, ignore, unignore, and
 * delete.  You must remove one or more of these before sending -[super start].
 */
@property (retain) NSMutableArray *validActions;

/** The parent App List view controller. */
@property (retain) AppListVC      *vc;

/* Selectors */

/**
 * Initializes the ActionHandler with the AppListVC that instantiated it.  You
 * MAY, but are not required to, override this selector.  You may also make
 * your own constructor, but it needs to accept an AppListVC and pass that
 * to -[super initWithVC:] in its implementation.
 */
- (id)initWithVC:(AppListVC *)vc_;

/**
 * Handles any button press on a UIAlertView.
 * 
 * If the pressed button is an OK, cancel, or no button, then the action
 * handler aborts, autoreleases itself, and returns control to the parent
 * AppListVC.
 */
- (void)alertView:(UIAlertView *)alertView
        didDismissWithButtonIndex:(NSInteger)buttonIndex;

/**
 * Performs the chosen action by calling _doActionCallback in a new thread and
 * shows a progress HUD while the action is being performed.  You MUST override
 * this selector and send -[super doAction] at the END of your implementation.
 */
- (void)doAction;

/**
 * Performs the chosen action.  DO NOT SEND THIS SELECTOR DIRECTLY; use
 * doAction instead.  You MUST override this selector in your subclass(es).
 * 
 * Do NOT send [super _doActionCallback] in your implementation.
 */
- (void)_doActionCallback;

/** Hides the progress HUD by sending _hideHUDCallback to the main thread. */
- (void)hideHUD;

/**
 * Hides the progress HUD.  DO NOT SEND THIS SELECTOR DIRECTLY; use hideHUD
 * instead.
 */
- (void)_hideHUDCallback;

/** Part of MBProgressHUDDelegate. */
- (void)hudWasHidden:(MBProgressHUD *)hud;

/**
 * Shows a UIAlertView for the result of the action using the given title and
 * text by sending _showResultWithTitleAndTextCallback: to the main thread.
 *  
 * @param title The title of the alert view.
 * @param text  The message text of the alert view.
 */
- (void)showResultWithTitle:(NSString *)title text:(NSString *)text;

/**
 * Shows a UIAlertView for the result of the action using the given title and
 * text.  DO NOT SEND THIS SELECTOR DIRECTLY; use showResultWithTitle:text:
 * instead.
 * 
 * @param array An array containing the requested title and message text in
 *              that order.
 */
- (void)_showResultWithTitleAndTextCallback:(NSArray *)array;

/**
 * Shows the chooser screen.  You MUST override this selector and send
 * -[super start] at the END of your implementation.
 * 
 * This selector retains the instance it is called on.
 */
- (void)start;

- (void)dealloc;

@end
