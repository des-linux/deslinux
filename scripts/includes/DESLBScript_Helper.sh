#!INCLUDE_ONLY
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

# Helper functions can call from DESLBScript.sh

export ARGS_MAKE_INSTALL="DESTDIR=${DLP_INSTALL_DIR} prefix='' PREFIX=''"
export ARGS_CONFIGURE="--build=${BUILDER_TARGET} --host=${DESL_TARGET} --prefix=/usr";

ToolchainDB(){
cat <<"EOF";
ADDR2LINE	addr2line
AR	ar
AS	as
CC	gcc
CXX	c++
CXXFILT	c++filt
CPP	cpp
ELFEDIT	elfedit
GXX	g++
GCC	gcc
GCOV	gcov
GPROF	gprof
LD	ld
LTODUMP	lto-dump
NM	nm
OBJCOPY	objcopy
OBJDUMP	objdump
RANLIB	ranlib
READELF	readelf
SIZE	size
STRINGS	strings
STRIP	strip
XX	g++
EOF
}

DSH_ExportToolchainInfo(){
	local x;
	local IFS=$'\n\r';
	local PROGS='';

	for x in `ToolchainDB`; do
		export ${x%%	*}="${DESL_TARGET}-${x#*	}"
		PROGS="${PROGS} ${x%%	*}=${DESL_TARGET}-${x#*	}"
	done

	for x in `ToolchainDB`; do
		PROGS="${PROGS} ${x%%	*}_FOR_BUILD=${BUILDER_TARGET}-${x#*	}"
		PROGS="${PROGS} BUILD_${x%%	*}=${BUILDER_TARGET}-${x#*	}"
		PROGS="${PROGS} HOST_${x%%	*}=${BUILDER_TARGET}-${x#*	}"
		PROGS="${PROGS} BUILD${x%%	*}=${BUILDER_TARGET}-${x#*	}"
		PROGS="${PROGS} HOST${x%%	*}=${BUILDER_TARGET}-${x#*	}"

		export ${x%%	*}_FOR_BUILD="${BUILDER_TARGET}-${x#*	}"
		export BUILD_${x%%	*}="${BUILDER_TARGET}-${x#*	}"
		export HOST_${x%%	*}="${BUILDER_TARGET}-${x#*	}"
		export BUILD${x%%	*}="${BUILDER_TARGET}-${x#*	}"
		export HOST${x%%	*}="${BUILDER_TARGET}-${x#*	}"
	done

	export DESL_TOOLCHAIN_PROGS="${PROGS}";
	return 0;
}


DSH_make(){
	make ${ARGS_MAKE_CORE} "${@}" || return ${?};
	return 0;
}

DSH_makeEx(){
	DSH_ExportToolchainInfo;
	DSH_make ${DESL_TOOLCHAIN_PROGS} "${@}" || return ${?};
	return 0;
}

DSH_makeInstall(){
	DSH_make install ${ARGS_MAKE_INSTALL} "${@}" || return ${?};
	return 0;
}

DSH_makeInstallEx(){
	DSH_makeEx install ${ARGS_MAKE_INSTALL} "${@}" || return ${?};
	return 0;
}

DSH_configure(){
	[ "${DESLB_SUPPORT_NATIVE_ISOLATION:-0}" = '1' ] && {
		${SHARED_SOURCE_DIR}/configure ${ARGS_CONFIGURE} "${@}" || return ${?};
		return 0;
	}

	./configure ${ARGS_CONFIGURE} "${@}" || return ${?};
	return 0;
}

DSH_configureEx(){
	DSH_ExportToolchainInfo
	DSH_configure ${DESL_TOOLCHAIN_PROGS} "${@}" || return ${?};
	return 0;
}

DSH_GetSharedDirectory(){ # package ID
	PackageLoad "${1}" "${PACKAGES_DIR}/${1}/DESLPackage.def" GSD || return ${?};
	SHARED_SOURCE_DIR="${SHARED_SOURCE_ROOT_DIR}/${GSD_Package_Source_RootDir}"
	return 0;
}

DSH_OpenBuildDirectory(){ # package ID
	:
}

DSH_CloseBuildDirectory(){ # package ID
	:
}

DSH_RemoveEmptyDirectories(){ # path
	local D="${1:-.}";
	local x;
	for x in `find ${D} -type d | sort -r`; do
		rmdir "${x}" 2> /dev/null
	done
	return 0;
}

DSH_MoveFiles(){ # src, dst, name match
	local x;
	local S="${1:-.}";
	local D="${2}";
	local M="${3}";
	local P;

	for x in `find "${S}" ${M:+ -name "${M}"}`; do
		[ -d "${x}" ] && continue;

		P="${x#${S}}";
		mkdir -p "${D}/${P%/*}" || return ${?};
		mv "${x}" "${D}/${P}" || return ${?};
	done
	return 0;
}
