# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="6"
inherit eutils java-pkg-2 java-ant-2

DESCRIPTION="A library that allows you to develop or extend Alice worlds directly in the NetBeans environment."
HOMEPAGE="http://www.alice.org/get-alice/alice-3-with-netbeans/"
SLOT="8.2"

FILE_V="${PV//./_}"
BASE_F="Alice3NetBeans8Plugin_${FILE_V}"
F="${BASE_F}.nbm"
SRC_URI="https://dev.gentoo.org/~fordfrog/distfiles/netbeans-8.2-build.xml.patch.bz2
	 http://www.alice.org/wp-content/uploads/2017/05/${F}"

LICENSE="ALICE3"
KEYWORDS="amd64 ~x86"
S="${WORKDIR}/netbeans"


CDEPEND="virtual/jdk:1.8
	~dev-java/netbeans-extide-${PV}
	~dev-java/netbeans-ide-${PV}
	~dev-java/netbeans-java-${PV}
	~dev-java/netbeans-platform-${PV}"

DEPEND="${CDEPEND}"
RDEPEND="${CDEPEND}"

INSTALL_DIR="/usr/share/${PN}-${SLOT}"
EANT_BUILD_XML="nbbuild/build.xml"
EANT_BUILD_TARGET="rebuild-cluster"
EANT_EXTRA_ARGS="-Drebuild.cluster.name=nb.cluster.java -Dext.binaries.downloaded=true -Dpermit.jdk8.builds=true"
EANT_FILTER_COMPILER="ecj-3.3 ecj-3.4 ecj-3.5 ecj-3.6 ecj-3.7"
JAVA_PKG_BSFIX="off"


src_unpack() {
	ewarn "This package may be not finished.  It's left for users to complete."

	cp -a "${DISTDIR}/${F}" "${T}"/${BASE_F}.zip
	mkdir -p "${WORKDIR}"
	cd "${WORKDIR}"
	unpack "${T}/${BASE_F}.zip"
	mkdir -p "${T}/org-alice-netbeans"
	cd "${T}/org-alice-netbeans"
	unpack "${S}/modules/org-alice-netbeans.jar"
	mkdir -p "${S}/update_tracking"
	cp -a "${FILESDIR}/org-alice-netbeans.xml.${PV}" org-alice-netbeans.xml
}

src_prepare() {
	cd "${T}/org-alice-netbeans"
	unpack netbeans-8.2-build.xml.patch.bz2

	einfo "Deleting bundled jars..."
	find -name "*.jar" -type f -delete

	einfo "Symlinking external libraries..."
	#java-pkg_jar-from --build-only --into javahelp/external javahelp jhall.jar jhall-2.0_05.jar

	java-pkg-2_src_prepare
	default
}

src_install() {
	cd "${S}"
	#insinto /usr/share/alice3
	#doins -r "${DISTDIR}"/Alice3NetBeans8Plugin_${FILE_V}.nbm

	insinto ${INSTALL_DIR}

	doins -r *

	dosym ${INSTALL_DIR} /usr/share/netbeans-nb-${SLOT}/alice
}

pkg_postinst() {
	true
	#elog "The NetBeans alice plugin as be installed in /usr/share/alice3."
	#elog "See http://alice3.pbworks.com/w/page/57586346/Download%20and%20Install%20Plugin"
	#elog "for details to install it."
}
