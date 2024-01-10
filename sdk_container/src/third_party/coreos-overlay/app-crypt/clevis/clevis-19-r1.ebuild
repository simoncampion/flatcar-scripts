# Copyright 2022-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson systemd

DESCRIPTION="Automated Encryption Framework"
HOMEPAGE="https://github.com/latchset/clevis"
SRC_URI="https://github.com/latchset/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE="+luks +tpm +dracut"

DEPEND="
	dev-libs/jose
	sys-fs/cryptsetup
	luks? (
		app-misc/jq
		dev-libs/libpwquality
		dev-libs/luksmeta
	)
	tpm? ( app-crypt/tpm2-tools )
	dracut? ( sys-kernel/dracut )
"
RDEPEND="${DEPEND}"
# The clevis meson build will not build certain features if certain executables are not found at build time, such as `tpm2_createprimary`.
# The meson function `find_program` that checks for the existence of the executables does not seem to search paths in ${ROOT}, but rather 
# under `/`. A fix to make sure that meson finds all binaries and decides to include all features is to install all runtime dependencies
# into the SDK.
BDEPEND="${DEPEND}"

PATCHES=(
	# From https://github.com/latchset/clevis/pull/347
	# Allows using dracut without systemd
	"${FILESDIR}/clevis-dracut.patch"
	# Fix for systemd on Gentoo
	"${FILESDIR}/clevis-meson.patch"
	# Flatcar-specific fixes
	"${FILESDIR}/clevis-dracut-flatcar.patch"
)

post_src_install() {
	# The meson build for app-crypt/clevis installs some files to ${D}${ROOT}. After that, Portage
	# copies from ${D} to ${ROOT}, leading to files ending up in, e.g., /build/amd64-usr/build/amd64-usr/.
	# To fix this, we move everything from ${D}${ROOT} to ${D}.
 	echo ${D}${ROOT}/ to ${D}
 	rsync -av ${D}${ROOT}/ ${D}
 	rm -rfv ${D}${ROOT}

 	systemd_enable_service cryptsetup.target clevis-luks-askpass.path
}