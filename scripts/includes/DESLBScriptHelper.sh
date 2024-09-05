#!INCLUDE_ONLY
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

# Helper functions can call from DESLBScript.sh

export DESL_MAKE="make ${MAKE_OPT}"
export DESL_MAKE_INSTALL="make DESTDIR=${DLP_INSTALL_DIR} prefix=/"

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
