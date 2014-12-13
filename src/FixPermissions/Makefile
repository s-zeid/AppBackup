CC = /home/scottywz/Sources/iphone-toolchain/toolchain/pre/bin/arm-apple-darwin9-gcc
LD = $(CC)
DEVICE = scottPhone

# Based on the iphonedevonlinux HelloWorldFirst sample, released under the MIT
# License.
# <http://code.google.com/p/iphonedevonlinux/source/browse/trunk/apps/HelloWorldFirst/Makefile>
# <http://www.opensource.org/licenses/mit-license.php>

LDFLAGS= -lobjc \
         -bind_at_load \
         -w

all:     FixPermissions sign

sign:
	ldid -S FixPermissions

clean:
	@rm -Rf FixPermissions
