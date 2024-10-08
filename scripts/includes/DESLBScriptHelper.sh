#!INCLUDE_ONLY
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

# Helper functions can call from DESLBScript.sh

export DESL_MAKE="make ${MAKE_OPT}"
export DESL_MAKE_INSTALL="make DESTDIR=${DLP_INSTALL_DIR} prefix=/"


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

ExportToolchainInfo(){
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

		export ${x%%	*}_FOR_BUILD="${BUILDER_TARGET}-${x#*	}"
		export BUILD_${x%%	*}="${BUILDER_TARGET}-${x#*	}"
		export HOST_${x%%	*}="${BUILDER_TARGET}-${x#*	}"
	done

	export DESL_TOOLCHAIN_PROGS="${PROGS}";
	return 0;
}

makeX(){
	ExportToolchainInfo
	${DESL_MAKE} ${DESL_TOOLCHAIN_PROGS} "${@}" || return ${?};
	return 0;
}

DESLBP_GetSharedDirectory(){ # package ID
	PackageLoad "${1}" "${PACKAGES_DIR}/${1}/DESLPackage.def" GSD || return ${?};
	SHARED_SOURCE_DIR="${SHARED_SOURCE_ROOT_DIR}/${GSD_Package_Source_RootDir}"
	return 0;
}

DESLBP_OpenBuildDirectory(){ # package ID
	:
}

DESLBP_CloseBuildDirectory(){ # package ID
	:
}

RunDESLBuilder(){
	case ${DESLB_RUN_IN_WORLD} in
		1) DESLB_SUBPROCESS=1 "${DESL_BUILDER}" "${@}" || return ${?};;
		*) DESLB_SUBPROCESS=1 "${CORETOOLS_DIR}/sh" "${DESL_BUILDER}" "${@}" || return ${?};;
	esac
	return 0;
}

DESLBuilder(){
	vinfo "Use 'RunDESLBuilder' instead"
	RunDESLBuilder "${@}"
	return ${?};
}
