#!INCLUDE_ONLY
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

RunScript(){
	case ${DESLB_RUN_IN_WORLD:-0} in
		1) RunCommand "${@}" || return ${?};;
		*) RunCommand "${CORETOOLS_DIR}/sh" "${@}" || return ${?};;
	esac
	return 0;
}

RunCommand(){
	case "${DESL_OUTPUT_VERBOSE:-0}" in
		0 | 1)
			"${@}" > /dev/null
			return ${?};
			;;

		* )
			"${@}"
			return ${?};
			;;
	esac
	return 127;
}

RunDESLBuilder(){
	case ${DESLB_RUN_IN_WORLD} in
		1) DESLB_SUBPROCESS=1 "${DESL_BUILDER}" "${@}" || return ${?};;
		*) DESLB_SUBPROCESS=1 "${CORETOOLS_DIR}/sh" "${DESL_BUILDER}" "${@}" || return ${?};;
	esac
	return 0;
}

RunDLPM(){
	RunScript "${SCRIPTS_DIR}/dlpm" "${@}"
	return ${?};
}

RunDLPI(){
	RunScript "${SCRIPTS_DIR}/dlpi" "${@}"
}

DESLBuilder(){
	vinfo "Use 'RunDESLBuilder' instead"
	RunDESLBuilder "${@}"
	return ${?};
}
