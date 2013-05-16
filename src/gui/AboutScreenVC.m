/* AppBackup
 * An iOS application that backs up and restores the saved data and
 * preferences of App Store apps.
 * 
 * Copyright (C) 2008-2013 Scott Zeid
 * http://s.zeid.me/projects/appbackup
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

// About screen view controller

#import <CoreFoundation/CoreFoundation.h>;
#import <UIKit/UIKit.h>;

#import "AboutScreenVC.h";
#import "util.h";

#define WEB_SITE @"http://s.zeid.me/projects/appbackup"

@implementation AboutScreenVC
@synthesize webView;
- (void)loadView {
 // Get some frames
 CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
 CGRect navBarFrame = self.navigationController.navigationBar.frame;
 NSInteger navBarHeight = navBarFrame.size.height;
 CGRect bounds = CGRectMake(appFrame.origin.x, appFrame.origin.y,
                            appFrame.size.width,
                            appFrame.size.height - navBarHeight);
 struct CGRect frame;
 // Set up main view
 self.view = [[[UIView alloc] initWithFrame:bounds] autorelease];
 UIView *view = self.view;
 view.backgroundColor = [UIColor whiteColor];
 // Configure the navigation bar
 NSString *title = [NSString stringWithFormat:[_ s:@"about_title"],
                    [[NSBundle mainBundle]
                     objectForInfoDictionaryKey:@"CFBundleDisplayName"]];
 self.navigationItem.title = title;
 // Make the bottom toolbar and add button
 frame = CGRectMake(0, bounds.size.height - navBarHeight, bounds.size.width,
                    navBarHeight);
 UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:frame];
 UIBarButtonItem *flexSpace;
 flexSpace = [[UIBarButtonItem alloc]
               initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
               target:nil action:nil];
 UIBarButtonItem *webSiteBtn = [[UIBarButtonItem alloc]
                                initWithTitle:[_ s:@"web_site"]
                                style:UIBarButtonItemStyleBordered
                                target:self action:@selector(goToWebSite:)];
 toolbar.items = [NSArray arrayWithObjects:flexSpace, webSiteBtn, flexSpace,
                                           nil];
 [flexSpace release];
 [webSiteBtn release];
 [view addSubview:toolbar];
 [toolbar release];
 // Make WebView
 frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height - navBarHeight);
 self.webView = [[[UIWebView alloc] initWithFrame:frame] autorelease];
 [view addSubview:webView];
}

- (void)viewDidAppear:(BOOL)animated {
 NSURL *url = [NSURL fileURLWithPath:[_ bundledFilePath:@"about.html"]];
 NSURLRequest *request = [NSURLRequest requestWithURL:url];
 [webView loadRequest:request];
 [super viewDidAppear:animated];
}

- (void)goToWebSite:(id)sender {
 // Called when you tap the Web Site button
  NSURL *url = [NSURL URLWithString:WEB_SITE];
  [[UIApplication sharedApplication] openURL:url];
}

- (void)dealloc {
 self.webView = nil;
 [super dealloc];
}
@end
