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

// About screen

@class AboutScreen : UIActionSheet {}
 // What to do when you click the "About" button
 - initWithGUI:gui {
  self = [super init];
  if (self) {
   self.gui = gui;
   [self setTitle:sprintf(_("about_title"), PRODUCT.name)];
   [self setDelegate:self];
   [self setBodyText:read(bundled_file_path("about.txt"))];
   [self addButtonWithTitle:_("web_site")];
   [self setCancelButtonIndex:[self addButtonWithTitle:_("ok")]];
  }
  return self;
 }
 // What to do when you close the about box
 - actionSheet:sheet didDismissWithButtonIndex:index {
  var action = [sheet buttonTitleAtIndex:index];
  if (action == _("web_site")) {
   url = [new NSURL initWithString:PRODUCT.web_site];
   [[UIApplication sharedApplication] openURL:url];
  }
 }
@end
