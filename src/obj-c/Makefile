CC = /home/scottywz/Sources/iphone-toolchain/toolchain/pre/bin/arm-apple-darwin9-gcc
LD = $(CC)
DEVICE = scottPhone

# Based on the iphonedevonlinux HelloToolchain sample, released under the MIT
# License.
# <http://code.google.com/p/iphonedevonlinux/source/browse/trunk/apps/HelloWorldFirst/Makefile>
# <http://www.opensource.org/licenses/mit-license.php>

LDFLAGS= -lobjc \
	 -bind_at_load \
	 -framework Foundation \
	 -framework CoreFoundation \
	 -framework UIKit \
	 -w

all:     AppBackupGUI sign

AppBackupGUI: AppBackupGUI.o AboutScreen.o AppBackup.o BackupAllAppsScreen.o \
	BackupOneAppScreen.o main.o MBProgressHud.o util.o
	 $(LD) $(LDFLAGS) -o $@ $^

sign:
	 scp AppBackupGUI mobile@$(DEVICE):/tmp
	 ssh mobile@$(DEVICE) ldid -S /tmp/AppBackupGUI
	 scp mobile@$(DEVICE):/tmp/AppBackupGUI .

%.o:     %.m
	 $(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

clean:
	 @rm -f AppBackupGUI
	 @rm -f *.o
