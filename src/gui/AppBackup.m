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

// AppBackup CLI Bridge

#import <UIKit/UIKit.h>

#import "ErrorHandler.h"
#import "util.h"

#import "AppBackup.h"

@implementation AppBackup {
 @private
 BDSKTask         *_shellTask;
 NSFileHandle     *_shellStdin;
 NSFileHandle     *_shellStdout;
 NSNumber         *_shellReturned;
 BOOL              _runningCommand;
 NSCondition      *_runningCommandCondition;
}

@synthesize apps = _apps;
@synthesize allBackedUp = _allBackedUp;
@synthesize anyBackedUp = _anyBackedUp;
@synthesize anyCorrupted = _anyCorrupted;


- (id)init {
 return [self initWithVC:nil];
}

- (id)initWithVC:(UIViewController *)vc {
 self = [super init];
 if (self) {
  _apps = [[NSMutableArray alloc] init];
  _allBackedUp = NO;
  _anyBackedUp = NO;
  _anyCorrupted = NO;
  _vc = [vc retain];
  _shellReturned = nil;
  _runningCommand = NO;
  _runningCommandCondition = [NSCondition new];
  // Start the CLI shell
  _shellTask = [[BDSKTask alloc] init];
#ifdef USE_CLI_PROXY
  _shellTask.launchPath = [_ bundledFilePath:@"appbackup-cli-proxy.app/appbackup-cli-proxy"];
#else
  _shellTask.launchPath = [_ bundledFilePath:@"appbackup-cli"];
#endif
  _shellTask.arguments = [NSArray arrayWithObjects:
                                   @"--robot=plist", @"shell", @"--null", nil];
  _shellTask.standardInput  = [NSPipe pipe];
  _shellTask.standardOutput = [NSPipe pipe];
  NSLog(@"starting the AppBackup shell using the command [\"%@\", \"%@\"]",
        _shellTask.launchPath,
        [_shellTask.arguments componentsJoinedByString:@"\", \""]);
  [_shellTask launch];
  _shellStdin  = [[_shellTask standardInput]  fileHandleForWriting];
  _shellStdout = [[_shellTask standardOutput] fileHandleForReading];
  // Wait for the shell to get ready
  NSData *ps1 = [_shellStdout readDataOfLength:1];
  if (ps1.length < 1 || ((char *)ps1.bytes)[0] != '\0') {
   // The shell failed to start properly
   if (ps1.length < 1)
    NSLog(@"appbackup-cli did not output any prompt");
   else if (((char *)ps1.bytes)[0] != '\0')
    NSLog(@"appbackup-cli did not output the correct prompt");
   NSLog(@"appbackup-cli failed to start properly");
   BOOL wasRunning = self.shellReturned == nil;
   [self terminateShellAndWaitUntilExit];
   if (!wasRunning)
    NSLog(@"appbackup-cli exited with return code %d",
          (int)[self.shellReturned integerValue]);
   if (_vc != nil) {
    NSString *text = [NSString stringWithFormat:
                                [_ s:@"error_shell_failed_to_start"],
                                PRODUCT_NAME];
    if (_vc.view != nil && _vc.view.window != nil)
     [_vc.view.window makeKeyAndVisible];
    [self _displayShellExitErrorWithText:text];
   }
  } else
   NSLog(@"appbackup-cli started properly");
 }
 return self;
}

- (NSString *)backupTimeTextForApp:(NSDictionary *)app {
 if (![[app objectForKey:@"useable"] boolValue])
  return [_ s:@"app_corrupted_list"];
 if ([[app objectForKey:@"ignored"] boolValue])
  return [_ s:@"baktext_ignored"];
 double t = [[app objectForKey:@"backup_time_unix"] doubleValue];
 if (t != 0.0) {
  NSString *d = [app objectForKey:@"backup_time_str"];
  if (d != nil && [d length])
   return [NSString stringWithFormat:[_ s:@"baktext_yes"], [_ localizeDate:d]];
 }
 return [_ s:@"baktext_no"];
}

- (NSDictionary *)doActionOnAllApps:(NSString *)action {
 NSArray *args = [NSArray arrayWithObject:@"--all"];
 NSDictionary *r = [self runCmd:action withArgs:args];
 NSDictionary *o = [r objectForKey:@"output"];
 NSArray *array = [o objectForKey:@"normal"];
 if ([array count] > 0 && [[r objectForKey:@"return_code"] intValue] == 0)
  [self _setAppsWithArray:array];
 return r;
}

- (NSDictionary *)doAction:(NSString *)action
                  onApp:(NSDictionary *)app {
 NSString *bundle_id = [app objectForKey:@"bundle_id"];
 NSArray *args = [NSArray arrayWithObjects:bundle_id, nil];
 NSDictionary *r = [self runCmd:action withArgs:args];
 return r;
}

- (void)findApps {
 NSDictionary *r = [self runCmd:@"list"];
 NSDictionary *o = [r objectForKey:@"output"];
 if ([r objectForKey:@"success"])
  [self _setAppsWithArray:[o objectForKey:@"normal"]];
 else
  [self _setAppsWithArray:nil];
}

- (void)_setAppsWithArray:(NSArray *)array {
 [_apps release];
 if (array != nil)
  _apps = [[NSMutableArray alloc] initWithArray:array];
 else
  _apps = [[NSMutableArray alloc] init];
 [self updateBackupInfo];
}

- (NSDictionary *)runCmd:(NSString *)cmd {
 NSDictionary *r = [self runCmd:cmd withArgs:[NSArray array]];
 return r;
}

- (NSDictionary *)runCmd:(NSString *)cmd withArgs:(NSArray *)args {
 // Wait for other commands to finish
 [_runningCommandCondition lock];
 while (_runningCommand != NO)
  [_runningCommandCondition wait];
 [_runningCommandCondition unlock];
 _runningCommand = YES;
 // Make sure the shell is actually running
 if (self.shellReturned != nil) {
  NSLog(@"the AppBackup shell is not running!");
  NSLog(@"it exited with return code %d",
        (int)[self.shellReturned integerValue]);
  if (_vc != nil) {
   NSString *text = [NSString stringWithFormat:
                               [_ s:@"error_shell_not_running"],
                               PRODUCT_NAME];
   [self _displayShellExitErrorWithText:text];
  }
  return nil;
 }
 // Send command to the shell
 if ([args count] > 0)
  NSLog(@"running AppBackup shell command [\"%@\", \"%@\"]", cmd,
        [args componentsJoinedByString:@"\", \""]);
 else
  NSLog(@"running AppBackup shell command [\"%@\"]", cmd);
 NSArray *cmdArray = [[NSArray arrayWithObjects:cmd, nil]
                      arrayByAddingObjectsFromArray:args];
 NSData *cmdPlist = [NSPropertyListSerialization
                     dataFromPropertyList:cmdArray
                     format:NSPropertyListXMLFormat_v1_0
                     errorDescription:nil];
 [_shellStdin writeData:cmdPlist];
 [_shellStdin writeData:[NSData dataWithBytes:"\0" length: 1]];
 // Wait for it to finish and receive result
 const int increment = 256;
 NSMutableData *resultPlist = [NSMutableData dataWithLength:increment];
 NSUInteger pos = 0;
 NSData *byteData;
 NSRange range = NSMakeRange(0, 1);
 while (true) {
  if (pos % increment == 0)
   [resultPlist increaseLengthBy:increment];
  byteData = [_shellStdout readDataOfLength:1];
  if (byteData.length < 1 || ((char *)byteData.bytes)[0] == '\0') {
   break;
  } else {
   range.location = pos;
   [resultPlist replaceBytesInRange:range withBytes:byteData.bytes];
   pos++;
  }
 }
 // Process result
 NSDictionary *resultDict
  = (NSDictionary *)[NSPropertyListSerialization
                     propertyListFromData:resultPlist
                     mutabilityOption:NSPropertyListImmutable
                     format:NULL errorDescription:nil];
 // Log return code
 NSObject *returnCode = [resultDict objectForKey:@"return_code"];
 if (returnCode != nil) {
  if ([returnCode isKindOfClass:[NSNumber class]])
   NSLog(@"command finished with return code %d",
         (int)[(NSNumber *)returnCode integerValue]);
  else
   NSLog(@"command finished with an INVALID TYPE for the return code!");
 } else
  NSLog(@"command finished withOUT a return code!");
 // Get Python tracebacks if there are any
 NSArray *tracebacks = [NSArray array];
 NSObject *output = [resultDict objectForKey:@"output"];
 if ([output isKindOfClass:[NSDictionary class]]) {
  NSObject *tracebacksMaybe = [(NSDictionary*)output objectForKey:@"traceback"];
  if ([tracebacksMaybe isKindOfClass:[NSArray class]] &&
      [(NSArray *)tracebacksMaybe count] > 0) {
   tracebacks = (NSArray *)tracebacksMaybe;
  }
 }
 // Display error if the shell exited
 if (self.shellReturned != nil) {
  NSLog(@"appbackup-cli exited with return code %d",
        (int)[self.shellReturned integerValue]);
  if ([tracebacks count] > 0) {
   // log caught tracebacks first
   NSLog(@"command also reported one or more Python errors:");
   for (int i = 0; i < [tracebacks count]; i++) {
    NSLog(@"%@", [tracebacks objectAtIndex:i]);
   }
  }
  if (_vc != nil) {
   NSString *text = [NSString stringWithFormat:
                               [_ s:@"error_shell_terminated_improperly"],
                               PRODUCT_NAME];
   [self _displayShellExitErrorWithText:text];
  }
 }
 // Otherwise, display Python tracebacks if there are any
 else if ([tracebacks count] > 0) {
  if (_vc != nil) {
   NSLog(@"command reported one or more Python errors:  (displayed to user)");
   NSString *text = [NSString stringWithFormat:
                               [_ s:@"error_unexpected_nonfatal"],
                               PRODUCT_NAME];
   [self _displayShellTracebacks:tracebacks withText:text];
  } else {
   NSLog(@"command reported one or more Python errors:");
   for (int i = 0; i < [tracebacks count]; i++) {
    NSLog(@"%@", [tracebacks objectAtIndex:i]);
   }
  }
 }
 _runningCommand = NO;
 [_runningCommandCondition signal];
 // Return result
 return resultDict;
}

- (NSNumber *)shellReturned {
 if (_shellReturned != nil)
  return _shellReturned;
 if (![_shellTask isRunning]) {
  _shellReturned = [NSNumber numberWithInt:_shellTask.terminationStatus];
  return _shellReturned;
 }
 return nil;
}

- (NSString *)starbucks {
 NSString *starbucks;
 NSDictionary *r = [self runCmd:@"starbucks"];
 NSDictionary *o = [r objectForKey:@"output"];
 if ([r objectForKey:@"success"])
  starbucks = [NSString stringWithString:[o objectForKey:@"normal"]];
 else
  starbucks = @"";
 return starbucks;
}

- (void)terminateShell {
 // Stop the shell
 if ([_shellTask isRunning]) {
  NSLog(@"terminating the shell");
  [_shellTask terminate];
 }
}

- (void)terminateShellAndWaitUntilExit {
 // Stop the shell and wait for it to exit
 if ([_shellTask isRunning]) {
  NSLog(@"terminating the shell");
  [_shellTask terminate];
  NSLog(@"waiting for the shell to exit");
  [_shellTask waitUntilExit];
  NSLog(@"shell exited with return code %d",
        (int)[self.shellReturned integerValue]);
 }
}

- (BOOL)updateAppAtIndex:(NSInteger)index {
 NSDictionary *app = [self.apps objectAtIndex:index];
 [app retain];
 NSArray *args = [NSArray arrayWithObjects:/*@"--uuid",*/
                  [app objectForKey:@"bundle_id"], nil];
 NSDictionary *r = [self runCmd:@"list" withArgs:args];
 [app release];
 NSDictionary *o = [r objectForKey:@"output"];
 NSDictionary *d = [NSDictionary dictionaryWithDictionary:
                    [[o objectForKey:@"normal"] objectAtIndex:0]];
 return [self updateAppAtIndex:index withDictionary:d];
}

- (BOOL)updateAppAtIndex:(NSInteger)index withDictionary:(NSDictionary *)dict {
 NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary:dict];
 if (true) {//[[md objectForKey:@"found"] boolValue]) {
  //[md removeObjectForKey:@"found"];
  NSDictionary *d = [NSDictionary dictionaryWithDictionary:md];
  [self.apps replaceObjectAtIndex:index withObject:d];
  [self updateBackupInfo];
  return YES;
 } else {
  [self.apps removeObjectAtIndex:index];
  [self updateBackupInfo];
  return NO;
 }
}

- (void)updateBackupInfo {
 _allBackedUp = ([self.apps count]) ? YES : NO;
 _anyBackedUp = NO;
 _anyCorrupted = NO;
 NSDictionary *app;
 int i;
 for (i = 0; i < [self.apps count]; i++) {
  app = [self.apps objectAtIndex:i];
  if ([[app objectForKey:@"useable"] boolValue]) {
   if ([[app objectForKey:@"backup_time_unix"] doubleValue] &&
       ![[app objectForKey:@"ignored"] boolValue])
    _anyBackedUp = YES;
   else _allBackedUp = NO;
  } else _anyCorrupted = YES;
 }
}

- (void)_displayShellExitErrorWithText:(NSString *)text {
 NSString *error = [NSString stringWithFormat:
                              @"(appbackup-cli exited with return code %d)",
                              (int)[self.shellReturned integerValue]];
 ErrorHandler *eh = [[ErrorHandler alloc]
                        initWithVC:_vc
                             error:error
                             title:[_ s:@"error_occurred_fatal"]
                              text:text
                           isFatal:YES];
 [eh performSelectorOnMainThread:@selector(showAlert)
     withObject:nil waitUntilDone:YES];
 [eh waitForErrorToBeDismissed];
 [eh release];
}

- (void)_displayShellTracebacks:(NSArray *)tracebacks
                       withText:(NSString *)text {
 NSString *error = [tracebacks componentsJoinedByString:@"\n"];
 ErrorHandler *eh = [[ErrorHandler alloc]
                        initWithVC:_vc
                             error:error
                             title:[_ s:@"error_occurred"]
                              text:text
                           isFatal:NO];
 [eh performSelectorOnMainThread:@selector(showAlert)
     withObject:nil waitUntilDone:YES];
 [eh waitForErrorToBeDismissed];
 [eh release];
}

- (void)dealloc {
 [self terminateShell];
 _runningCommandCondition = nil;
 _shellReturned = nil;
 _shellStdin = nil;
 _shellStdout = nil;
 [_shellTask release];
 [_apps release];
 [_vc release];
 [super dealloc];
}
@end
