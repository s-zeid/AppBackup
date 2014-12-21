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

#import "util.h"

#import "AppBackup.h"

@implementation AppBackup
@synthesize apps;
@synthesize allBackedUp;
@synthesize anyBackedUp;
@synthesize anyCorrupted;

- (id)init {
 self = [super init];
 if (self) {
  self.apps = [NSMutableArray array];
  self.allBackedUp = NO;
  self.anyBackedUp = NO;
  self.anyCorrupted = NO;
  _runningTasks = [NSMutableArray array];
  // Start task
  _task = [[BDSKTask alloc] init];
  _task.launchPath = [_ bundledFilePath:@"appbackup-cli"];
  _task.arguments = [NSArray arrayWithObjects:
                             @"--robot=plist", @"shell", @"--null", nil];;
  _task.standardInput  = [NSPipe pipe];
  _task.standardOutput = [NSPipe pipe];
  [_runningTasks addObject:_task];
  [_task launch];
  _stdin  = [[_task standardInput]  fileHandleForWriting];
  _stdout = [[_task standardOutput] fileHandleForReading];
  NSData *ps1 = [_stdout readDataOfLength:1];
  NSData *null = [NSData dataWithBytes:"\0" length:1];
  if (ps1.length < 1 || ![ps1 isEqualToData:null]) {
   [self terminateAllRunningTasks];
   [self release];
   return nil;
  }
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
 NSString *data_uuid = [app objectForKey:@"data_uuid"];
 NSArray *args = [NSArray arrayWithObjects:/*@"--uuid", */data_uuid, nil];
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
 if (array != nil)
  self.apps = [NSMutableArray arrayWithArray:array];
 else
  self.apps = [NSMutableArray array];
 [self updateBackupInfo];
}

- (NSDictionary *)runCmd:(NSString *)cmd {
 NSDictionary *r = [self runCmd:cmd withArgs:[NSArray array]];
 return r;
}

- (NSDictionary *)runCmd:(NSString *)cmd withArgs:(NSArray *)args {
 NSData *null = [NSData dataWithBytes:"\0" length:1];
 // Send command to the shell
 NSArray *cmdArray = [[NSArray arrayWithObjects:cmd, nil]
                      arrayByAddingObjectsFromArray:args];
 NSData *cmdPlist = [NSPropertyListSerialization
                     dataFromPropertyList:cmdArray
                     format:NSPropertyListXMLFormat_v1_0
                     errorDescription:nil];
 [_stdin writeData:cmdPlist];
 [_stdin writeData:null];
 // Wait for it to finish and receive result
 const int increment = 256;
 NSMutableData *resultPlist = [NSMutableData dataWithLength:increment];
 unsigned long long pos = 0;
 NSData *byteData;
 NSRange range = NSMakeRange(0, 1);
 while (true) {
  if (pos % increment == 0)
   [resultPlist increaseLengthBy:increment];
  byteData = [_stdout readDataOfLength:1];
  if (byteData.length < 1 || [byteData isEqualToData:null]) {
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
 return resultDict;
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

- (void)terminateAllRunningTasks {
 // Stop any running tasks
 BDSKTask *task;
 int i;
 for (i = 0; i < [_runningTasks count]; i++) {
  task = [_runningTasks objectAtIndex:i];
  if ([task isRunning])
   [task terminate];
 }
 [_runningTasks removeAllObjects];
}

- (BOOL)updateAppAtIndex:(NSInteger)index {
 NSDictionary *app = [apps objectAtIndex:index];
 NSArray *args = [NSArray arrayWithObjects:/*@"--uuid",*/
                  [app objectForKey:@"data_uuid"], nil];
 NSDictionary *r = [self runCmd:@"list" withArgs:args];
 NSDictionary *o = [r objectForKey:@"output"];
 NSDictionary *d = [NSDictionary dictionaryWithDictionary:
                    [[o objectForKey:@"normal"] objectAtIndex:0]];
 BOOL ret = [self updateAppAtIndex:index withDictionary:d];
 return ret;
}

- (BOOL)updateAppAtIndex:(NSInteger)index withDictionary:(NSDictionary *)dict {
 NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary:dict];
 if (true) {//[[md objectForKey:@"found"] boolValue]) {
  [md removeObjectForKey:@"found"];
  NSDictionary *d = [NSDictionary dictionaryWithDictionary:md];
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
 self.allBackedUp = ([apps count]) ? YES : NO;
 self.anyBackedUp = NO;
 self.anyCorrupted = NO;
 NSDictionary *app;
 int i;
 for (i = 0; i < [apps count]; i++) {
  app = [apps objectAtIndex:i];
  if ([[app objectForKey:@"useable"] boolValue]) {
   if ([[app objectForKey:@"backup_time_unix"] doubleValue] &&
       ![[app objectForKey:@"ignored"] boolValue])
    self.anyBackedUp = YES;
   else self.allBackedUp = NO;
  } else self.anyCorrupted = YES;
 }
}

- (void)dealloc {
 self.apps = nil;
 self.allBackedUp = NO;
 self.anyBackedUp = NO;
 self.anyCorrupted = NO;
 [self terminateAllRunningTasks];
 _task = nil;
 _stdin = nil;
 _stdout = nil;
 _runningTasks = nil;
 [super dealloc];
}
@end
