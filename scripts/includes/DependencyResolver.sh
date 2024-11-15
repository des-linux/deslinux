#!INCLUDE_ONLY
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

SolveDepends_SourceOnly(){ # Mode
	local x;
	local MODE="${1:-/Prepare}";

	[ ! "${Package_ImportCoreInfo:--}" = '-' ] && {
		RunDESLBuilder ${ARGS_RAW_STRING} /M:${MODE} /Package:${Package_ImportCoreInfo} || return ${?}
	}

	for x in `ConfigFileList "${PKG_FILE}" 'BuildDepends_SourceOnly'`; do
		RunDESLBuilder ${ARGS_RAW_STRING} /M:${MODE} /Package:${x} || return ${?}
	done
	return 0;
}

SolveDepends_BuildOnly(){ # Build:Y, Install:N, Auto-dev:N, ForBuilder:N
	SolveDepends_DLP 'BuildDepends_BuildOnly' 1 0 0 0 || return ${?};
	return 0;
}

SolveDepends_BuildTools(){ # Build:Y, Install:Y, Auto-dev:N, ForBuilder:Y
	SolveDepends_DLP 'BuildDepends_BuildTools' 1 1 0 1 || return ${?};
	SolveDepends_DLP 'RuntimeDepends' 1 1 0 1 || return ${?};
	return 0;
}

SolveDepends_Library(){ # Build:Y, Install:N, Auto-dev:Y, ForBuilder:N
	SolveDepends_DLP 'BuildDepends_Library' 1 0 0 0 || return ${?};
	SolveDepends_DLP 'BuildDepends_Library' 0 1 1 0 || return ${?};

	SolveDepends_DLP 'Depends' 1 1 1 0 || return ${?};
	SolveDepends_DLP 'Depends' 1 1 0 0 || return ${?};

	SolveDepends_DLP 'BuildDenepds_Toolchain' 1 1 0 0 || return ${?};
	SolveDepends_DLP 'BuildDenepds_Toolchain' 0 1 1 0 || return ${?};
	return 0;
}

SolveDepends_DLP(){ # Section, F:Build, F:Install, F:AutoDev, InstallTo
	local x;
	local L_SECTION="${1:--}";
	local L_BUILD="${2:-0}";
	local L_INSTALL="${3:-0}";
	local L_AUTODEV="${4:-0}";
	local L_FORBUILDER="${5:-0}";

	local L_DLP_DEFAULT="${DLP_DIR}";
	local L_INSTALL_DEFAULT_DIR="${CURRENT_TOOLCHAIN_USR_DIR:-${TOOLCHAIN_USR_DIR}}";
	[ "${L_FORBUILDER}" = '1' ] && {
		L_DLP_DEFAULT="${DLP_BUILDER_DIR}";
		L_INSTALL_DEFAULT_DIR="${TOOLCHAIN_BUILDER_DIR}";
	}

	[ "${L_FORBUILDER}" = '1' ] && {
		L_INSTALL_DEFAULT_DIR="${CURRENT_TOOLCHAIN_TOOLS_DIR:-${TOOLCHAIN_TOOLS_DIR}}";
	}

	local x_ORG L_ARCH L_DLP_DIR L_INSTALL_DIR F_DEVONLY F_TOOLCHAINS;

	for x in `ConfigFileList "${PKG_FILE}" "${L_SECTION}"`; do
		F_DEVONLY=0;
		F_TOOLCHAINS=0;

		L_ARCH='';
		L_DLP_DIR="${L_DLP_DEFAULT}";
		L_INSTALL_DIR="${L_INSTALL_DEFAULT_DIR}";

#		[ "${x:0:1}" = '!' ] && {
#			x="${x:1}";
#			F_DEVONLY=1;
#		}

		x_ORG="${x}";
		[ "${L_AUTODEV}" = '1' ] && {
			x="${x}-dev";
#		} || {
#			[ "${F_DEVONLY:-0}" = '1' ] && {
#				vinfo "Skip package '${x}': '-dev' only flag is on"
#				continue;
#			}
		}

		# Prevent loop (Some packages requires builder's arch version of own in building.)
		[ "${L_FORBUILDER}" = '1' ] && [ "${x}" = "${DESL_BUILD_PACKAGE}" ] && [ "${DESL_INTERNAL_TOOLS:-0}" = '1' ] && {
			continue;
		}
		# Directory patch
		case "${x}" in
			bootstrap | bootstrap/* )
				L_DLP_DIR="${DLP_BOOTSTRAP_DIR}";
				L_INSTALL_DIR="${BOOTSTRAP_DIR}";
				F_TOOLCHAINS=1;
			;;

			toolchain-base | toolchain-base/* )
				L_DLP_DIR="${DLP_BASEARCH_DIR}";
				L_INSTALL_DIR="${TOOLCHAIN_BASEARCH_DIR}";
				F_TOOLCHAINS=1;
			;;

			toolchain | toolchain/* )
				L_DLP_DIR="${DLP_TOOLCHAIN_DIR}";
				L_INSTALL_DIR="${TOOLCHAIN_DIR}";
				F_TOOLCHAINS=1;
			;;

			* )
				[ "${L_FORBUILDER}" = '1' ] && {
					L_ARCH='/Arch:BUILD';
				}
			;;
		esac

		# Check installed
		RunDLPI /Check /Root:${L_INSTALL_DIR} /ID:${x} || {

			# Check: DLP exists
			RunDLPM /FindPackage "${x}" /DLPDir:${L_DLP_DIR} /Quiet || {
				[ "${L_BUILD}" = '1' ] && {
					# No DLP && BUILD flag = 1
					RunDESLBuilder ${ARGS_RAW_STRING} /M:/Build /Package:${x_ORG} ${L_ARCH} || return ${?}
				} || {
					# No DLP && BUILD flag = !1 (Ignore this package)
					continue
				}
			}

			# Install DLP
			case "${L_INSTALL}" in
				0) ;;
				1)
					RunDLPM /Install /Root:${L_INSTALL_DIR} "${x}" /DLPDir:${L_DLP_DIR} || return ${?}
				;;
				2)
					[ "${F_TOOLCHAINS}" = '1' ] && {
						RunDLPM /Install /Root:${L_INSTALL_DIR} "${x}" /DLPDir:${L_DLP_DIR} || return ${?}
					}
				;;
				*) error "Unknown Install flag [${L_INSTALL}:${F_TOOLCHAINS}]"; return 1;;
			esac
		}

	done

	return 0;
}
