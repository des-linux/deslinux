#!INCLUDE_ONLY
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

DESLBPM_SelectDLPM(){
	local MODE="${1}";
	local PID="${2}";

	local R=0;
	case "${ARGS_OPT_LONG_Package}" in
		bootstrap/* | toolchain/* )
			ARGS_OPT_LONG_Tools=0;
			ARGS_OPT_LONG_Library='-';
		;;
	esac

	case "${ARGS_OPT_LONG_Tools:-0}:${ARGS_OPT_LONG_Library:-0}" in
		'0:-' )
			BuilderDLPM_Library "${MODE}" "${PID}-dev" 1
			R=${?};
			BuilderDLPM_Library "${MODE}" "${PID}" 1
			return ${R};
		;;
		'-:0' )
			BuilderDLPM_Tools "${MODE}" "${PID}" 1
			return ${?};
		;;
	esac
	error "Unsupported install dir specified"
	return 1;
}

DESLBPM_RunDLPM(){
	DESLBPM_SelectDLPM "${@}"
	local R=${?};
	case "${R}" in
		251 )
			error "Package '${ARGS_OPT_LONG_Package}' is not built."
			return 1;;
	esac
	return ${R};
}

DESLBPM(){
	local R=0;

	case "${ARGS_OPT_LONG_Install:-0}:${ARGS_OPT_LONG_Remove:-0}:${ARGS_OPT_LONG_Package:+-}" in
		'-:0:-' )
			DESLBPM_RunDLPM /Install "${ARGS_OPT_LONG_Package}"
			return ${R};
		;;
		'0:-:-' )
			DESLBPM_RunDLPM /Remove "${ARGS_OPT_LONG_Package}"
			return ${R};
		;;
		* )
			error 'Unsupported option specified.'
			error 'DESLBuilder /DLP </Install, /Remove> /Package:<PackageID>'
			return 1;
		;;
	esac

	return 0;
}
