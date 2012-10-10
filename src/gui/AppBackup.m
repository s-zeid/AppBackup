/* AppBackup
 * An iPhoneOS application that backs up and restores the saved data and
 * preferences of App Store apps.
 * 
 * Copyright (C) 2008-2012 Scott Zeid
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

#import "BDSKTask.h";
#import "util.h";

#import "AppBackup.h";

@implementation AppBackup
@synthesize apps;
@synthesize allBackedUp;
@synthesize anyBackedUp;
@synthesize anyCorrupted;
@synthesize runningTasks;

- (id)init {
 self = [super init];
 if (self) {
  self.apps = [NSMutableArray array];
  self.allBackedUp = NO;
  self.anyBackedUp = NO;
  self.anyCorrupted = NO;
  self.runningTasks = [NSMutableArray array];
 }
 return self;
}

- (NSString *)backupTimeTextForApp:(NSDictionary *)app {
 if (![[app objectForKey:@"useable"] boolValue])
  return [_ s:@"app_corrupted_list"];
 if ([[app objectForKey:@"ignored"] boolValue])
  return [_ s:@"baktext_ignored"];
 NSString *d = [app objectForKey:@"backup_time"];
 if (d != nil && [d length])
  return [NSString stringWithFormat:[_ s:@"baktext_yes"], [_ localizeDate:d]];
 return [_ s:@"baktext_no"];
}

- (NSDictionary *)doActionOnAllApps:(NSString *)action {
 NSArray *args = [NSArray arrayWithObject:@"--all"];
 NSDictionary *r = [self runCmd:action withArgs:args];
 return r;
}

- (NSDictionary *)doAction:(NSString *)action
                  onApp:(NSDictionary *)app {
 NSString *guid = [app objectForKey:@"guid"];
 NSArray *args = [NSArray arrayWithObjects:@"--guid", guid, nil];
 NSDictionary *r = [self runCmd:action withArgs:args];
 return r;
}

- (void)findApps {
 NSDictionary *r = [self runCmd:@"list"];
 if ([r objectForKey:@"success"])
  self.apps = [NSMutableArray arrayWithArray:[r objectForKey:@"data"]];
 else
  self.apps = [NSMutableArray array];
 [self updateBackupInfo];
}

- (NSDictionary *)runCmd:(NSString *)cmd {
 NSDictionary *r = [self runCmd:cmd withArgs:[NSArray array]];
 return r;
}

- (NSDictionary *)runCmd:(NSString *)cmd withArgs:(NSArray *)args {
 // Start task
 BDSKTask *task = [[BDSKTask alloc] init];
 task.launchPath = [_ bundledFilePath:@"appbackup-cli"];
 task.arguments = [[NSArray arrayWithObjects:@"--plist", cmd, nil]
                   arrayByAddingObjectsFromArray:args];
 task.standardOutput = [NSPipe pipe];
 [runningTasks addObject:task];
 [task launch];
 // Wait for it to finish and process result
 NSFileHandle *handle = [[task standardOutput] fileHandleForReading];
 NSData *data = [handle readDataToEndOfFile];
 [handle closeFile];
 [runningTasks removeObject:task];
 NSDictionary *dict = (NSDictionary *)[NSPropertyListSerialization
                       propertyListFromData:data
                       mutabilityOption:NSPropertyListImmutable
                       format:NULL errorDescription:nil];
 [task release];
 return dict;
}

- (NSString *)starbucks {
 NSString *starbucks;
 NSDictionary *r = [self runCmd:@"starbucks"];
 if ([r objectForKey:@"success"])
  starbucks = [NSString stringWithString:[r objectForKey:@"data"]];
 else
  starbucks = @"";
 return starbucks;
}

- (void)terminateAllRunningTasks {
 // Stop any running tasks
 BDSKTask *task;
 int i;
 for (i = 0; i < [runningTasks count]; i++) {
  task = [runningTasks objectAtIndex:i];
  if ([task isRunning])
   [task terminate];
 }
 [runningTasks removeAllObjects];
}

- (BOOL)updateAppAtIndex:(NSInteger)index {
 NSDictionary *app = [apps objectAtIndex:index];
 NSArray *args = [NSArray arrayWithObjects:@"--guid",
                  [app objectForKey:@"guid"], nil];
 NSDictionary *r = [self runCmd:@"list" withArgs:args];
 NSDictionary *d = [NSDictionary dictionaryWithDictionary:
                    [[r objectForKey:@"data"] objectAtIndex:0]];
 BOOL ret = [self updateAppAtIndex:index withDictionary:d];
 return ret;
}

- (BOOL)updateAppAtIndex:(NSInteger)index withDictionary:(NSDictionary *)dict {
 NSDictionary *app = [apps objectAtIndex:index];
 NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary:dict];
 if ([[md objectForKey:@"found"] boolValue]) {
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
   if ([[app objectForKey:@"backup_time"] length] &&
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
 self.runningTasks = nil;
 [super dealloc];
}
@end
