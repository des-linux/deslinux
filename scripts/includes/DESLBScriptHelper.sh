#!INCLUDE_ONLY
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

# Helper functions can call from DESLBScript.sh

export DESL_MAKE="make ${MAKE_OPT}"

DESLBP_GetSharedDirectory(){ # package ID
	PackageLoad "${1}" "${PACKAGES_DIR}/${1}/DESLPackage.def" GSD || return ${?};
	echo "${SHARED_SOURCE_ROOT_DIR}/${GSD_Package_Source_RootDir}"
	return 0;
}

DESLBP_OpenBuildDirectory(){ # package ID
	:
}

DESLBP_CloseBuildDirectory(){ # package ID
	:
}
