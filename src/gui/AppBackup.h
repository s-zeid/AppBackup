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

// AppBackup CLI Bridge (header)

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "BDSKTask.h"

@interface AppBackup : NSObject {
 @protected
 NSMutableArray *apps;
 BOOL            allBackedUp;
 BOOL            anyBackedUp;
 BOOL            anyCorrupted;
 @private
 UIApplication  *_gui;
 BDSKTask       *_shellTask;
 NSFileHandle   *_shellStdin;
 NSFileHandle   *_shellStdout;
 NSNumber       *_shellReturned;
}
@property (retain)   NSMutableArray *apps;
@property (assign)   BOOL            allBackedUp;
@property (assign)   BOOL            anyBackedUp;
@property (assign)   BOOL            anyCorrupted;
@property (readonly) NSNumber       *shellReturned;
- (id)init;
- (id)initWithGUI:(UIApplication *)gui;
- (NSString *)backupTimeTextForApp:(NSDictionary *)app;
- (NSDictionary *)doActionOnAllApps:(NSString *)action;
- (NSDictionary *)doAction:(NSString *)action onApp:(NSDictionary *)app;
- (void)findApps;
- (NSDictionary *)runCmd:(NSString *)cmd;
- (NSDictionary *)runCmd:(NSString *)cmd withArgs:(NSArray *)args;
- (NSString *)starbucks;
- (void)terminateShell;
- (BOOL)updateAppAtIndex:(NSInteger)index;
- (BOOL)updateAppAtIndex:(NSInteger)index withDictionary:(NSDictionary *)dict;
- (void)updateBackupInfo;
- (void)dealloc;
@end
