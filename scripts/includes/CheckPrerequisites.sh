#!INCLUDE_ONLY
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

RunCheckPrerequisites(){
	CheckPrerequisites_Core || return ${?};

	[ "${DESLB_BUILDING_BOOTSTRAP:+1}" = '1' ] && return 0;
	CheckPrerequisites_Bootstrap || return ${?};

	[ "${PACKAGE_ROOT_CATEGORY}" = 'toolchain-base' ] && return 0;


	[ "${PACKAGE_ROOT_CATEGORY}" = 'toolchain' ] && return 0;
	CheckPrerequisites_Toolchain || return ${?};

	return 0;
}

CheckPrerequisites_Core(){

	# 'MakeCPIO' ('dlpm' cannot use at this point)
	[ ! -e "${BOOTSTRAP_DIR}/bin/MakeCPIO" ] && {
		RunDESLBuilder /Package:bootstrap/MakeCPIO /M:/Build || return ${?};

	}

	return 0;
}

CheckPrerequisites_Bootstrap(){

	[ ! -e "${BOOTSTRAP_DIR}/desl_bootstrap" ] && {
		RunDESLBuilder /Package:bootstrap /M:/Build || return ${?};
	}

	return 0;
}

CheckPrerequisites_Toolchain(){

	[ ! -e "${TOOLCHAIN_DIR}/desl_toolchain" ] && {
		error 'DEBUG: No toolchain: Use /Platform /Add /Arch:${DESL_ARCH} to install'
		return 1;
	}

	return 0;
}
