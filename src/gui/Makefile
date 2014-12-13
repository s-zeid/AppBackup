CC = ios-clang
#CC = /home/scottywz/Sources/iphone-toolchain/toolchain/pre/bin/arm-apple-darwin9-gcc
LD = $(CC)
LIPO = arm-apple-darwin11-lipo
DEVICE = scottPhone

# Based on the iphonedevonlinux HelloToolchain sample, released under the MIT
# License.
# <http://code.google.com/p/iphonedevonlinux/source/browse/trunk/apps/HelloWorldFirst/Makefile>
# <http://www.opensource.org/licenses/mit-license.php>

CFLAGS = -arch armv6
LDFLAGS= -lobjc -arch armv6 \
	 -bind_at_load \
	 -framework Foundation \
	 -framework CoreFoundation \
	 -framework CoreGraphics \
	 -framework UIKit \
	 -w

all:     AppBackupGUI sign

AppBackupGUI: util.o BDSKTask.o AppBackup.o MBProgressHUD.o \
	ActionHandler.o OneAppHandler.o AllAppsHandler.o \
	AboutScreenVC.o AppListVC.o TestScreenVC.o AppBackupGUI.o main.o
	 $(LD) $(LDFLAGS) -o $@ $^

sign:
	 #scp AppBackupGUI mobile@$(DEVICE):/tmp
	 #ssh mobile@$(DEVICE) ldid -S /tmp/AppBackupGUI
	 #scp mobile@$(DEVICE):/tmp/AppBackupGUI .
	 ldid -S AppBackupGUI

%.o:     %.m
	 $(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

clean:
	 @rm -f AppBackupGUI
	 @rm -f *.o
