# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
DESCRIPTION="AMD Accelerated Parallel Processing (APP) SDK"
HOMEPAGE=\
"http://developer.amd.com/tools-and-sdks/opencl-zone/amd-accelerated-parallel-processing-app-sdk"
LICENSE="AMD-APPSDK"
KEYWORDS="~amd64 ~x86"
SLOT="0"
IUSE="+clinfo examples +opencl-icd-loader opencv openmp"
RDEPEND="!<dev-util/amdstream-2.6
	examples? (
		media-libs/glew:0=
		opencv? ( media-libs/opencv:0/2.4 )
	)
	media-libs/freeglut
	openmp? ( sys-libs/libomp )
	sys-devel/gcc:*
	sys-devel/llvm
	virtual/opengl
	!opencl-icd-loader? ( >=virtual/opencl-3 )"
DEPEND="${RDEPEND}"
# Circa Jan 30, 2017
MD5SUM_x86_64="79f976374e292059b68c035ae5e32ac9" # v3.0.130.136
MD5SUM_x86="ab99423b3dfbb5ea1969b9c8854f7a70" # v3.0.130.136
# Circa Mar 15, 2016
#MD5SUM_x86_64="be19706292e4f554085d5d71dd62d0b0" # v3.0.130.135
#MD5SUM_x86="9da7a1e0ab5390592618a4e347c2bd13" # v3.0.130.135
MY_V="$(ver_cut 1-2).130.136-GA"
X86_AT="AMD-APP-SDKInstaller-v${MY_V}-linux32.tar.bz2"
AMD64_AT="AMD-APP-SDKInstaller-v${MY_V}-linux64.tar.bz2"
MY_P_AMD64="AMD-APP-SDK-v${MY_V}-linux64.sh"
MY_P_AMD32="AMD-APP-SDK-v${MY_V}-linux32.sh"
inherit multilib-minimal unpacker
SRC_URI="abi_x86_64? ( ${AMD64_AT} )
	 abi_x86_32? ( ${X86_AT} )"
S="${WORKDIR}"
RESTRICT="fetch mirror strip"
REQUIRED_USE=""

pkg_setup() {
	if grep -r -e "pni" /proc/cpuinfo 2>/dev/null 1>/dev/null \
		|| grep -r -e "sse3" /proc/cpuinfo 2>/dev/null 1>/dev/null ; then
		einfo "CPU is compatible"
	elif grep -r -e "sse2" /proc/cpuinfo 2>/dev/null 1>/dev/null ; then
		einfo "CPU is compatible"
	else
		ewarn "SSE2 or SSE3 is required for CPU support"
	fi
}

pkg_nofetch() {
	einfo "AMD doesn't provide direct download links. Please download"
	einfo "${ARCHIVE} from ${HOMEPAGE}"
}

src_unpack() {
	default
	cd "${WORKDIR}" || die
	if use amd64 || use amd64-linux ; then
		X_MD5SUM=$(md5sum "${DISTDIR}/${AMD64_AT}" | cut -f1 -d" ")
		[[ "${X_MD5SUM}" != "${MD5SUM_x86_64}" ]] && die "md5sum failed"
		unpacker ${MY_P_AMD64}
	else
		X_MD5SUM=$(md5sum "${DISTDIR}/${X86_AT}" | cut -f1 -d" ")
		[[ "${X_MD5SUM}" != "${MD5SUM_x86}" ]] && die "md5sum failed"
		unpacker ${MY_P_X86}
	fi
}

src_compile() {
	MAKEOPTS+=" -j1"
	use examples && cd samples/opencl && default
}

src_install() {
	dodir /opt/AMDAPP
	cp -R "${S}/"* "${ED}/opt/AMDAPP" || die "Install failed!"
	if [[ "${ABI}" == "amd64" ]] ; then
		if has_version 'app-eselect/eselect-opencl' ; then
			dodir "/usr/$(get_libdir)/OpenCL/vendors/amdapp/"
			dosym /opt/AMDAPP/lib/x86_64/sdk/libOpenCL.so \
				"/usr/$(get_libdir)/OpenCL/vendors/amdapp/libOpenCL.so"
			dosym /opt/AMDAPP/lib/x86_64/sdk/libOpenCL.so.1 \
				"/usr/$(get_libdir)/OpenCL/vendors/amdapp/libOpenCL.so.1"
			dosym /opt/AMDAPP/lib/x86_64/sdk/libamdocl64.so \
				"/usr/$(get_libdir)/OpenCL/vendors/amdapp/libamdocl64.so"
			dosym /opt/AMDAPP/lib/x86_64/libamdocl12cl64.so \
				"/usr/$(get_libdir)/OpenCL/vendors/amdapp/libamdocl12cl64.so"
		fi
		insinto "/etc/OpenCL/vendors"
		echo "/opt/AMDAPP/lib/x86_64/sdk/libamdocl64.so" > "${T}/amdappocl64.icd"
		doins "${T}/amdappocl64.icd"

		cat <<-EOF > "${T}"/50${P}-64
			LDPATH="/opt/AMDAPP/lib/x86_64"
		EOF
		doenvd "${T}"/50${P}-64

		if ! use clinfo ; then
			rm -rf "${ED}/opt/AMDAPP/bin/x86_64/clinfo"
		fi

		if ! use opencl-icd-loader ; then
			rm -rf "${ED}/opt/AMDAPP/lib/x86_64/"libOpenCL.so*
		fi
	elif [[ "${ABI}" == "x86" ]] ; then
		if has_version 'app-eselect/eselect-opencl' ; then
			dodir "/usr/$(get_libdir)/OpenCL/vendors/amdapp/"
			dosym /opt/AMDAPP/lib/x86/libOpenCL.so \
				"/usr/$(get_libdir)/OpenCL/vendors/amdapp/libOpenCL.so"
			dosym /opt/AMDAPP/lib/x86/libOpenCL.so.1 \
				"/usr/$(get_libdir)/OpenCL/vendors/amdapp/libOpenCL.so.1"
		fi
		insinto "/etc/OpenCL/vendors"
		echo "/opt/AMDAPP/lib/x86/libamdocl32.so" > "${T}/amdappocl32.icd"
		doins "${T}/amdappocl32.icd"

		cat <<-EOF > "${T}"/50${P}-32
			LDPATH="/opt/AMDAPP/lib/x86"
		EOF
		doenvd "${T}"/50${P}-32

		if ! use clinfo ; then
			rm -rf "${ED}/opt/AMDAPP/bin/x86/clinfo"
		fi

		if ! use opencl-icd-loader ; then
			rm -rf "${ED}/opt/AMDAPP/lib/x86/"libOpenCL.so*
		fi
	fi
}

pkg_postinst() {
	einfo "This package is deprecated."
	einfo "For the compatible hardware list see:"
	# Circa Dec 13, 2015
	einfo "http://developer.amd.com/tools-and-sdks/opencl-zone/amd-accelerated-parallel-processing-app-sdk/system-requirements-driver-compatibility/"
	einfo "The GPU OpenCL drivers are compatibile up to GCN 2"
}
