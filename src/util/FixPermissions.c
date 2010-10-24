/* AppBackup
 * An iPhoneOS application that backs up and restores the saved data and
 * preferences of App Store apps.
 * 
 * Copyright (C) 2008-2010 Scott Wallace
 * http://www.scott-wallace.net/iphone/appbackup
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
 * 
 */

#define AB_STORAGE_ROOT "/var/mobile/Library/Preferences/AppBackup"

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
 
 if ((dirfd = open(AB_STORAGE_ROOT, O_RDONLY)) == -1) {
  mkdir(AB_STORAGE_ROOT, S_IRUSR | S_IWUSR | S_IXUSR | S_IRGRP | S_IXGRP |
                         S_IROTH | S_IXOTH);
 } else {
  close(dirfd);
 }
 
 ret = walk(AB_STORAGE_ROOT, mobile_uid, mobile_gid);
 return ret;
}
