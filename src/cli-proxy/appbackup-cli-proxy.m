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

// CLI proxy client

#include <stdio.h>

#import <Foundation/Foundation.h>


#define CLI_HOST @"127.0.0.1"
#define CLI_PORT 14121


int cli_proxy(int argc, char **argv) {
 NSLog(@"connecting to CLI server\n");
 CFReadStreamRef cfReadStream;
 CFWriteStreamRef cfWriteStream;
 CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)CLI_HOST, CLI_PORT, &cfReadStream, &cfWriteStream);
 NSInputStream *inputStream = (NSInputStream *)cfReadStream;
 NSOutputStream *outputStream = (NSOutputStream *)cfWriteStream;
 [inputStream retain];
 [outputStream retain];
 [inputStream open];
 [outputStream open];
 NSLog(@"connected to CLI server\n");
 
 int r, n;
 bool started = false;
 unsigned char buf[1];
 while (true) {
  NSLog(@"%@", (started) ? @"reading command output\n" : @"reading initial prompt\n");
  buf[0] = 'r';
  n = 0;
  while (buf[0] != '\0') {
   r = 0;
   while (r == 0)
    r = (int)[inputStream read:buf maxLength:1];
   if (r < 0)
    return (-r)*10;
   n++;
   if (r > 0) {
    fprintf(stdout, "%c", buf[0]);
    fflush(stdout);
   }
  }
  NSLog(@"read %d byte(s)\n", n);
  
  if (!started)
   started = true;
  
  NSLog(@"writing command input\n");
  buf[0] = 'w';
  n = 0;
  while (buf[0] != '\0') {
   buf[0] = fgetc(stdin);
   r = 0;
   while (r == 0)
    r = (int)[outputStream write:buf maxLength:1];
   if (r < 0)
    return (-r)*10+1;
   n++;
  }
  NSLog(@"wrote %d byte(s)\n", n);
 }
 
 return 0;
}


int main(int argc, char **argv) {
 NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
 int ret = cli_proxy(argc, argv);
 [p drain];
 return ret;
}

