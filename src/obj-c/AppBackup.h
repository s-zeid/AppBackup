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

// AppBackup CLI Bridge (header)

@interface AppBackup : NSObject {
 NSMutableArray *apps;
 BOOL all_backed_up;
 BOOL any_backed_up;
 BOOL any_corrupted;
}
- (id)init;
- (NSString *)backupTimeTextForApp:(NSMutableDictionary *app);
- (NSMutableDictionary *)doActionOnAllApps:(NSString *)action;
- (NSMutableDictionary *)doAction:(NSString *)action
                         onApp:(NSMutableDictionary)app;
- (void)findApps;
- (NSMutableDictionary *)runCmd:(NSString *)cmd;
- (NSMutableDictionary *)runCmd:(NSString *)cmd withArgs:(NSArray *)args
- (NSString *)starbucks;
- (BOOL)updateAppAtIndex:(NSUInteger)index;
- (void)updateBackupInfo;
@end
