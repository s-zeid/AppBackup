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

// Error handler class

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "AppBackup.h"
#import "util.h"

#import "ErrorHandler.h"


// WARNING:  [[UIApplication sharedApplication] openURL:...] will *silently*
// fail if the email address is invalid!
// ERROR_REPORT_EMAIL can be set to the empty string to disable emailing.
#define ERROR_REPORT_EMAIL @"support@s.zeid.me"
#define ERROR_REPORT_SUBJECT \
         [NSString stringWithFormat:@"%@ runtime error", \
                    PRODUCT_NAME]
#define ERROR_REPORT_MESSAGE @"What were you doing when the error happened?\n\n"

#define LOG_ROOT CONFIG_ROOT @"/logs"
#define LOG_NAME_DEAD_PARROT    @"dead-parrot.txt"
#define LOG_NAME_APPBACKUPGUI   @"AppBackupGUI.log"
#define LOG_NAME_FIXPERMISSIONS @"FixPermissions.log"


@implementation ErrorHandler

- (id)initWithVC:(UIViewController *)vc
       withError:(NSString *)error withTitle:(NSString *)title
        withText:(NSString *)text isFatal:(BOOL)isFatal {
 self = [super init];
 if (self) {
  _vc                 = vc;
  _error              = error;
  _title              = title;
  _text               = text;
  _isFatal            = isFatal;
  _screen             = nil;
  _dismissedCondition = nil;
  _sendButtonIndex    = -1;
  _exitButtonIndex    = -1;
  _cancelButtonIndex  = -1;
 }
 return self;
}

- (void)showAlert {
 return [self showAlertWithWindow:nil];
}

- (void)showAlertWithWindow:(UIWindow *)window {
 [self performSelectorOnMainThread:
	@selector(_showAlertCallbackWithWindow:)
       withObject:window waitUntilDone:YES];
}

- (void)_showAlertCallbackWithWindow:(UIWindow*)window {
 // format the UIAlertView message and try to save it as a log file
 _deadParrot = [NSString stringWithFormat:
                          @"%@\n___________________________\n\n%@",
                          _text, _error];
 [[NSFileManager defaultManager]
  createFileAtPath:LOG_ROOT @"/" LOG_NAME_DEAD_PARROT
  contents:[_deadParrot dataUsingEncoding:NSUTF8StringEncoding]
  attributes:nil];
 // set up the UIAlertView
 _screen = [[UIAlertView alloc] init];
 _screen.delegate = self;
 _screen.title = _title;
 _screen.message = _deadParrot;
 if ([ERROR_REPORT_EMAIL length] > 0) {
  _sendButtonIndex = [_screen addButtonWithTitle:[_ s:@"send_error_report"]];
  if (!_isFatal)
   _exitButtonIndex = [_screen addButtonWithTitle:[_ s:@"exit_without_sending"]];
 }
 if (!_isFatal) {
  _cancelButtonIndex = [_screen addButtonWithTitle:[_ s:@"ok"]];
  [_screen setCancelButtonIndex:_cancelButtonIndex];
 }
 if (window != nil) {
  [window addSubview:_screen];
  [window makeKeyAndVisible];
 }
 [_screen show];
 [self retain];
}

- (void)waitForErrorToBeDismissed {
 _dismissedCondition = [NSCondition new];
 [_dismissedCondition lock];
 while (_screen != nil)
  [_dismissedCondition wait];
 [_dismissedCondition unlock];
 return;
}

- (void)alertView:(UIAlertView *)alertView
        didDismissWithButtonIndex:(NSInteger)buttonIndex {
 // What to do when you close the error screen
 [_screen autorelease];
 if (buttonIndex == _sendButtonIndex) {
  NSLog(@"And now for something completely different:\n%@", [self _easterEgg]);
  // email error report
  [self _emailErrorReport];
 }
 if (buttonIndex == _exitButtonIndex) {
  NSLog(@"And now for something completely different:\n%@", [self _easterEgg]);
  // fatal error xor user requested exit
  abort();
 }
 [self release];
 _screen = nil;
 if (_dismissedCondition != nil)
  [_dismissedCondition signal];
}
  
- (void)_emailErrorReport {
 // Find out how to send it
 BOOL useMailComposer = NO;
 BOOL mfmcvcCanSendMail = NO;
 @try {
  // prefer MFMailComposeViewController
  mfmcvcCanSendMail = [MFMailComposeViewController canSendMail];
  useMailComposer = YES;
 } @catch (NSException *exc) {
  // fall back to mailto: method; probably on iOS 2.x
  useMailComposer = NO;
 }
 if (useMailComposer && !mfmcvcCanSendMail)
  useMailComposer = NO;
 
 if (useMailComposer) {
  // Using MFMailComposeViewController

  // Get contents of log files
  NSData *deadparrot_log     = [_deadParrot dataUsingEncoding:NSUTF8StringEncoding];
  NSData *appbackupgui_log   = [self _getLogAsData:LOG_NAME_APPBACKUPGUI];
  NSData *fixpermissions_log = [self _getLogAsData:LOG_NAME_FIXPERMISSIONS];
  // Set up the message
  MFMailComposeViewController *mcvc = [[MFMailComposeViewController alloc] init];
  [mcvc setToRecipients:[NSArray arrayWithObjects:ERROR_REPORT_EMAIL, nil]];
  [mcvc setSubject:ERROR_REPORT_SUBJECT];
  [mcvc setMessageBody:
         [NSString stringWithFormat:@"%@\n___________________________\n",
                    ERROR_REPORT_MESSAGE]
        isHTML:NO];
  // Add logs
  [mcvc addAttachmentData:deadparrot_log mimeType:@"text/plain"
                 fileName:LOG_NAME_DEAD_PARROT];
  [mcvc addAttachmentData:appbackupgui_log mimeType:@"text/plain"
                 fileName:LOG_NAME_APPBACKUPGUI];
  [mcvc addAttachmentData:fixpermissions_log mimeType:@"text/plain"
                 fileName:LOG_NAME_FIXPERMISSIONS];
  // Send it
  mcvc.mailComposeDelegate = self;
  [_vc presentModalViewController:mcvc animated:YES];
 } else {
  // mailto: fallback
  
  // Get contents of log files
  NSString *appbackupgui_log   = [self _getLogAsString:LOG_NAME_APPBACKUPGUI];
  NSString *fixpermissions_log = [self _getLogAsString:LOG_NAME_FIXPERMISSIONS];
  // Format message
  NSString *subject = ERROR_REPORT_SUBJECT;
  NSString *message = [NSString stringWithFormat:
                                 @"%@\n___________________________\n\n%@ %@:\n\n%@"
                                 @"\n___________________________\n\n%@"
                                 @"\n___________________________\n\n%@"
                                 @"\n___________________________\n\n",
                                 ERROR_REPORT_MESSAGE,
                                 @"Contents of", LOG_NAME_DEAD_PARROT, _deadParrot,
                                 appbackupgui_log, fixpermissions_log
                      ];
  NSString *escapedSubject = [subject stringByAddingPercentEscapesUsingEncoding:
                                       NSUTF8StringEncoding];
  NSString *escapedMessage = [message stringByAddingPercentEscapesUsingEncoding:
                                       NSUTF8StringEncoding];
  NSString *url = [NSString stringWithFormat:@"mailto:%@?subject=%@&body=%@",
                             ERROR_REPORT_EMAIL, escapedSubject,
                             escapedMessage];
  // Send it
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
  if (_isFatal)
   abort();
 }
}

- (void)mailComposeController:(MFMailComposeViewController *)mcvc
        didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
 [_vc dismissModalViewControllerAnimated:YES];
 _vc.view = _vc.view;
 if (_isFatal)
  abort();
}

- (NSData *)_getLogAsData:(NSString *)name {
 NSString *path = [NSString stringWithFormat:@"%@/%@", LOG_ROOT, name];
 NSData *log = [NSData dataWithContentsOfFile:path];
 if (log == nil)
  log = [@"[could not read file]" dataUsingEncoding:NSUTF8StringEncoding];
 return log;
}

- (NSString *)_getLogAsString:(NSString *)name {
 NSString *path = [NSString stringWithFormat:@"%@/%@", LOG_ROOT, name];
 NSString *log = [NSString stringWithContentsOfFile:path
                           encoding:NSUTF8StringEncoding error:NULL];
 if (log == nil)
  log = @"[could not read file]";
 return [NSString stringWithFormat:@"Contents of %@:\n\n%@", path, log];
}

- (void)dealloc {
 _error              = nil;
 _title              = nil;
 _text               = nil;
 _screen             = nil;
 _dismissedCondition = nil;
 _sendButtonIndex    = -1;
 _exitButtonIndex    = -1;
 _cancelButtonIndex  = -1;
 [super dealloc];
}

- (NSString *)_easterEgg {
 NSString *easterEgg;
 if (_isFatal)
  easterEgg =
   @"\"It's not pining, it's passed on.  This %@ is no more!  It has ceased to"
   @" be.  It's expired and gone to meet its maker.  This is a late %@.  It's"
   @" a stiff.  Bereft of life, it rests in peace.  If you hadn't nailed it to"
   @" the perch it would be pushing up the daisies.  It's rung down the curtain"
   @" and joined the choir invisible!  This is an ex-%@!\"";
 else
  easterEgg =
   @"\"Now that's what I call a dead %@.\"\n\n"
   @"\"No, no.  It's stunned.\"\n\n"
   @"\"Look may lad, I've had just about enough of this.  That %@ is definitely"
   @" deceased.  And when I bought it not half an hour ago, you assured me that"
   @" its lack of movement was due to it being 'tired and shagged out after a"
   @" long squawk'.\"\n\n"
   @"\"It's probably pining for the fjords.\"\n\n"
   @"\"Pining for the fjords?  What kind of talk is that?!\"";
 return [easterEgg stringByReplacingOccurrencesOfString:@"%@"
                   withString:PRODUCT_NAME];
}
@end
