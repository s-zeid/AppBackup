/* AppBackup
 * An iOS application that backs up and restores the saved data and
 * preferences of App Store apps.
 * 
 * Copyright (C) 2008-2012 Scott Zeid
 * http://me.srwz.us/projects/appbackup
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

// Please excuse my shitty C code :)

#define APPBACKUP_CONFIG_DIR "/var/mobile/Library/Preferences/AppBackup"

#include <dirent.h>
#include <fcntl.h>
#include <grp.h>
#include <limits.h>
#include <pwd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

void exit_if_not_dir(char *path) {
 if (!isdir(path)) {
  printf("error: %s is not a directory\n", path);
  exit(EXIT_FAILURE);
 }
}

int isdir(char *path) {
 struct stat sb;
 if (lstat(path, &sb) == -1) {
  perror("stat");
  exit(EXIT_FAILURE);
 }
 if (S_ISDIR(sb.st_mode)) {
  return 1;
 }
 return 0;
}

int main(int argc, char **argv) {
 struct passwd *mobile_pwnam;
 struct group  *mobile_group;
 uid_t          mobile_uid;
 gid_t          mobile_gid;
 int            dirfd, ret;
 
 mobile_pwnam = getpwnam("mobile");
 mobile_group = getgrnam("mobile");
 if (mobile_pwnam == NULL || mobile_group == NULL) {
  return 2;
 }
 mobile_uid   = mobile_pwnam->pw_uid;
 mobile_gid   = mobile_group->gr_gid;
 
 exit_if_not_dir("/var/mobile");
 exit_if_not_dir("/var/mobile/Library");
 exit_if_not_dir("/var/mobile/Library/Preferences");
 if ((dirfd = open(APPBACKUP_CONFIG_DIR, O_RDONLY)) == -1) {
  mkdir(APPBACKUP_CONFIG_DIR, S_IRUSR | S_IWUSR | S_IXUSR | S_IRGRP | S_IXGRP |
                              S_IROTH | S_IXOTH);
 } else {
  close(dirfd);
 }
 exit_if_not_dir(APPBACKUP_CONFIG_DIR);
 
 ret = walk(APPBACKUP_CONFIG_DIR, mobile_uid, mobile_gid);
 return ret;
}

int walk(char *name, uid_t uid, gid_t gid) {
 DIR           *d;
 struct dirent *dir;
 char          *cwd, *abspath;
 
 chown(name, uid, gid);
 chmod(name, S_IRUSR | S_IWUSR | S_IXUSR | S_IRGRP | S_IXGRP | S_IROTH |
             S_IXOTH);
 
 cwd = malloc(PATH_MAX + 1);
 realpath(".", cwd);
 printf("%s/\n", name);
 chdir(name);
 
 d = opendir(name);
 if (d == NULL) {
  return 1;
 }
 while ((dir = readdir(d)) != NULL) {
  if (strcmp(dir->d_name, ".") == 0 || strcmp(dir->d_name, "..") == 0) {
   continue;
  }
  if (dir->d_type == DT_DIR) {
   abspath = malloc(PATH_MAX + 1);
   exit_if_not_dir(dir->d_name);
   realpath(dir->d_name, abspath);
   walk(abspath, uid, gid);
   free(abspath);
  } else if (dir->d_type == DT_REG) {
   printf("%s/%s\n", name, dir->d_name);
   chown(dir->d_name, uid, gid);
   chmod(dir->d_name, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
  }
 }
 closedir(d);
 chdir(cwd);
 free(cwd);
 return 0;
}
