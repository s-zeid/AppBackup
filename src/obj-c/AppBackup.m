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

// AppBackup CLI Bridge

#import "util.h";
#import "AppBackupCommand.h";

@implementation AppBackup
- (id)init {
 self = [super init];
 if (self) {
  apps = [NSArray array];
  all_backed_up = NO;
  any_backed_up = NO;
  any_corrupted = NO;
 }
 return self;
}

- (NSString *)backupTimeTextForApp:(NSMutableDictionary *app) {
 if (![app objectForKey:@"useable"])
  return _(@"app_corrupted_list");
 if ([app objectForKey:@"ignored"])
  return _(@"baktext_ignored");
 NSString *date = [app objectForKey:@"backup_text"];
 if (date) return [NSString stringWithFormat:_(@"baktext_yes"),
                   localize_date(date)];
 return _(@"baktext_no");
}

- (NSMutableDictionary *)doActionOnAllApps:(NSString *)action {
 NSArray *args = [NSArray arrayWithObjects:action, @"--all"];
 NSMutableDictionary *r = [self runCmd:cmd withArgs:args];
 return r;
}

- (NSMutableDictionary *)doAction:(NSString *)action
                         onApp:(NSMutableDictionary)app {
 NSString *guid = [app objectForKey:@"guid"];
 NSArray *args = [NSArray arrayWithObjects:action, @"--guid", guid];
 NSMutableDictionary *r = [self runCmd:cmd withArgs:args];
 return r;
}

- (void)findApps {
 NSMutableDictionary *r = [self runCmd:@"list"];
 if ([r objectForKey:@"success"])
  apps = ([NSArray arrayWithArray:[r objectForKey:@"data"]]);
 else
  apps = [NSArray array];
}

- (NSMutableDictionary *)runCmd:(NSString *)cmd {
 NSMutableDictionary *r = [self runCmd:cmd withArgs:[NSArray array]];
 return r;
}

- (NSMutableDictionary *)runCmd:(NSString *)cmd withArgs:(NSArray *)args {
 // Start task
 NSString *path = bundled_file_path(@"appbackup-cmd");
 NSArray *use_args = [[NSArray arrayWithObject:@"--plist"]
                      arrayByAddingObjectsFromArray:args];
 task = [NSTask launchedTaskWithLaunchPath:path arguments:use_args];
 // Wait for it to finish (should I use [NSTask waitUntilExit]?)
 BOOL finished = NO;
 while (!finished) {
  if (task != nil && [task isRunning])
   finished = NO;
 }
 // Process result
 NSData *data = [[task standardOutput] readDataToEndOfFile];
 NSMutableDictionary *dict = (NSMutableDictionary *)[NSPropertyListSerialization
                      propertyListFromData:data
                      mutabilityOption:NSPropertyListMutableContainersAndLeaves
                      format:NULL errorDescription:nil];
 return dict;
}

- (NSString *)starbucks {
 NSString *starbucks;
 NSMutableDictionary *r = [self runCmd:@"starbucks"];
 if ([r objectForKey:@"success"])
  s = [NSString stringWithString:[r objectForKey:@"data"]];
 else
  s = @"";
 return s;
}

- (BOOL)updateAppAtIndex:(NSInteger)index {
 NSMutableDictionary *app = [apps objectAtIndex:index];
 NSArray *args = [NSArray arrayWithObjects:@"--guid",
                  [app objectForKey:@"guid"]];
 NSMutableDictionary *r = [self runCmd:@"list" withArgs:args];
 NSMutableDictionary *d = [NSMutableDictionary
                           dictionaryWithDictionary:[r objectForKey:@"data"]];
 if ([d objectForKey:@"found"]) {
  [d removeObjectForKey:@"found"];
  [apps replaceObjectAtIndex:index withObject:d];
  [self updateBackupInfo];
  return YES;
 } else {
  [apps removeObjectAtIndex:index];
  [self updateBackupInfo];
  return NO;
 }
}

- (void)updateBackupInfo {
 self.all_backed_up = ([apps count]) ? YES : NO;
 self.any_backed_up = NO;
 self.any_corrupted = NO;
 *NSMutableDictionary app;
 for (int i = 0; i < [apps count]; i++) {
  app = [apps objectAtIndex:i];
  if ([app objectForKey:@"useable"]) {
   if ([[app objectForKey:@"backup_time"] length] &&
       ![app objectForKey:@"ignored"])
    self.any_backed_up = YES;
   else self.all_backed_up = NO;
  } else self.any_corrupted = YES;
 }
}
@end
