#!INCLUDE_ONLY
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

RunCheckPrerequisites(){

	CheckPrerequisites_Core || return ${?};

	[ "${DESLB_BUILDING_BOOTSTRAP:-0}" = '1' ] && return 0;
	[ "${PACKAGE_ROOT_CATEGORY}" = 'bootstrap' ] && return 0;

	CheckPrerequisites_Bootstrap || return ${?};

	[ "${PACKAGE_ROOT_CATEGORY}" = 'toolchain-base' ] && return 0;

	[ "${PACKAGE_ROOT_CATEGORY}" = 'toolchain' ] && return 0;

	CheckPrerequisites_Toolchain || return ${?};

	CheckPrerequisites_Toolchain_Builder || return ${?};

	return 0;
}

CheckPrerequisites_Core(){

	# 'MakeCPIO' ('dlpm' cannot use at this point. '/Install = DESLInstall()' will install directly)
	[ ! -e "${BOOTSTRAP_DIR}/bin/MakeCPIO" ] && {
		RunDESLBuilder ${ARGS_RAW_STRING} /Package:bootstrap/MakeCPIO /M:/Build || return ${?};

	}

	return 0;
}

CheckPrerequisites_Bootstrap(){

	[ ! -e "${BOOTSTRAP_DIR}/desl_bootstrap" ] && {
		RunDESLBuilder ${ARGS_RAW_STRING} /Package:bootstrap /M:/Build || return ${?};
	}

	return 0;
}

CheckPrerequisites_Toolchain(){

	[ ! -e "${TOOLCHAIN_DIR}/desl_toolchain" ] && {
		RunDESLBuilder ${ARGS_RAW_STRING} /Package:toolchain /M:/Build || return ${?};
	}

	return 0;
}

CheckPrerequisites_Toolchain_Builder(){
	[ ! -e "${TOOLCHAIN_TOOLS_DIR}/desl_toolchain_tools" ] && {
		RunDESLBuilder ${ARGS_RAW_STRING} /Package:toolchain/tools /M:/Build || return ${?};
		RunDESLBuilder ${ARGS_RAW_STRING} /Package:toolchain/headers /M:/Build || return ${?};
	}

	return 0;
}
