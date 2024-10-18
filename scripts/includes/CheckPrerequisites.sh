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

	CheckPrerequisites_BuildTools_Core || return ${?};

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

	[ ! -e "${TOOLCHAIN_BUILDER_DIR}/desl_toolchain" ] && {
		RunDESLBuilder ${ARGS_RAW_STRING} /Package:toolchain /M:/Build /Arch:${BUILDER_ARCH} || return ${?};
	}

	return 0;
}

# Call from ExecBuildScript
CheckPrerequisites_BuildTools_Core(){
	local x;
	local F="${TOOLCHAIN_TOOLS_CORE_DIR}/desl_toolchain_core":
	[ ! -e "${F}" ] && {
		for x in DESLinux/MakeCPIO dev/make core/kheaders; do
			CheckPrerequisites_CheckCoreDLP "${x}" || return ${?};
		done
		touch "${F}" || return ${?};
	}

	return 0;
}

CheckPrerequisites_CheckCoreDLP(){
	local x="${1}";

	RunDLPI /Check /Root:${TOOLCHAIN_TOOLS_CORE_DIR} /ID:${x} || {
		RunDLPM /FindPackage "${x}" /DLPDir:${DLP_BUILDER_DIR} /Quiet || {
			DESLB_PREREQ_USE_BOOTSTRAP=1 RunDESLBuilder ${ARGS_RAW_STRING} /M:/Build /Package:${x} /Arch:BUILD || return ${?}
		}
		RunDLPM /Install /Root:${TOOLCHAIN_TOOLS_CORE_DIR} "${x}" /DLPDir:${DLP_BUILDER_DIR} || return ${?}
	}

	return 0;
}
