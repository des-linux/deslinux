#!INCLUDE_ONLY
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

. "${INCLUDES_DIR}/DESLBPackageReader.sh"

BuilderRunScriptEx(){
	case "${DESL_OUTPUT_VERBOSE:-0}" in
		0 | 1 )
			"${@}" 3>&1 4>&2 1>/dev/null 2>&1
			return ${?};
			;;
		* )
			"${@}" 3>&1 4>&2
			return ${?};
			;;
	esac
	return 127;
}

BuilderStartMessage(){
	infoex "[${DESLB_NESTLV}] ${DESL_BUILD_PACKAGE}: ${1}"
	return 0;
}

BuilderInitialize(){
	PKG_FILE="${PACKAGES_DIR}/${DESL_BUILD_PACKAGE}/DESLPackage.def";
	PackageLoad "${DESL_BUILD_PACKAGE}" "${PKG_FILE}";
	return ${?};
}

# Depends type			When
# [Depends]			= BuildDepends_Library (+ '-dev' package) & RuntimeDepends
# [BuildDepends_SourceOnly]	/Download, /Extract
# [BuildDepends_BuildOnly]	RunScripts
# [BuildDepends_Library]	RunScripts
# [BuildDepends_BuildTools]	RunScripts
# [RuntimeDepends]		Install by dlpm

BuilderRunScript(){
	BuilderInitialize "${1}"

	BuilderSolveDepends_BuildOnly || return ${?};
	BuilderSolveDepends_BuildTools || return ${?};
	BuilderSolveDepends_Library || return ${?};

	BuilderRunScriptEx unshare -m "${DESLB_SH}" "${SCRIPTS_DIR}/ExecBuildScript" "${@}" || return ${?};
	return ${?};
}

BuilderDownload(){
	BuilderInitialize Download || return ${?};

	BuilderSolveDepends_SourceOnly /Download || return ${?};

	vinfo ' Checking for download necessity...'
	[ "${Package_Source_SaveTo}" = '' ] && {
		vinfo '  No source file required'
		return 0;
	}

	local PKG_ARC_FILE="${DL_CACHE_DIR}/${Package_Source_SaveTo}"

	[ -e "${PKG_ARC_FILE}" ] && {
		vinfo '  Already downloaded'
		return 0;
	}

	BuilderStartMessage 'Download'

	local PKG_ARC_URL="${Package_Source_BaseURI}/${Package_Source_File}"
	local PKG_ARC_DL="${PKG_ARC_FILE}.dl"
	rm -f "${PKG_ARC_DL}"

	case "${PKG_ARC_URL}" in
		http://* | https://* )
			RunCommand wget --no-check-certificate -O "${PKG_ARC_DL}" "${PKG_ARC_URL}" || {
				error 'Failed to download package file'
				return 1;
			}
		;;
		file://* )
			error NOT IMPL
			return 53;
		;;
		* )
			error '  Unsupported protocol specified'
			return 1;
		;;
	esac

	[ ! "${Package_Source_SHA256}" = '-' ] && {
		local PKG_ARC_DL_SHA256=`sha256sum "${PKG_ARC_DL}"`;
		local IFS=' ';
		set -- ${PKG_ARC_DL_SHA256}
		PKG_ARC_DL_SHA256="${1}";

		[ "${Package_Source_SHA256}" = '?' ] && {
			error " SHA256: ${PKG_ARC_DL_SHA256}"
			sleep 1
			Package_Source_SHA256="${PKG_ARC_DL_SHA256}";
		}

		[ ! "${PKG_ARC_DL_SHA256}" = "${Package_Source_SHA256}" ] && {
			error 'Missmatch checksum'
			error " Downloaded: ${PKG_ARC_DL_SHA256}"
			error " Expected  : ${Package_Source_SHA256}"
			return 1;
		}
	}
	mv "${PKG_ARC_DL}" "${PKG_ARC_FILE}"

	return 0;
}

BuilderExtract(){
	BuilderInitialize Extract || return ${?};

	BuilderSolveDepends_SourceOnly /Extract || return ${?};

	mkdir -p "${BUILD_DIR}"
	mkdir -p "${SHARED_SOURCE_ROOT_DIR}"

	vinfo ' Checking for extract necessity...'
	case "${Package_Source_BaseURI}" in
		'' | '-' )
			vinfo '  No source file required.'
			return 0;
		;;
	esac

	[ -e "${SHARED_SOURCE_ROOT_DIR}/${Package_Source_RootDir}" ] && {
		vinfo '  Already extracted'
		return 0;
	}

	BuilderStartMessage 'Extract'

	local PKG_ARC_FILE="${DL_CACHE_DIR}/${Package_Source_SaveTo}"
	[ ! -e "${PKG_ARC_FILE}" ] && {
		error "  Source file `${PKG_ARC_FILE}` is not downloaded."
		return 2;
	}

	local EXTRACT_DIR="${BUILD_ROOT_DIR}/extracting"
	[ -e "${EXTRACT_DIR}" ] && {
		warning '  Removing previous extract directory'
		rm -rf "${EXTRACT_DIR}"
		[ -e "${EXTRACT_DIR}" ] && {
			error '  Failed to remove previous extract directory'
			return 3;
		}
	}

	mkdir "${EXTRACT_DIR}"

	vinfo "  '${PKG_ARC_FILE}'..."
	case "${Package_Source_FileExts}" in
		.zip )
			RunCommand unzip -d "${EXTRACT_DIR}" "${PKG_ARC_FILE}"
			;;
		.tar | .tar.gz | .tar.xz | .tar.bz2 | .tar.lzma )
			RunCommand tar xvf "${PKG_ARC_FILE}" -C "${EXTRACT_DIR}"
			;;
		.tar.lzo )
			RunCommand lzop -dc "${PKG_ARC_FILE}" | tar xv -C "${EXTRACT_DIR}"
			;;
		* )
			error "   Unsupported compress mode"
			return 7;
			;;
	esac

	local R=${?};

	[ ! "${R}" = '0' ] && {
		error "  Failed to extract"
		rm -rf "${EXTRACT_DIR}"
		return 4;
	}

	[ "${Package_Source_MakeDir:-0}" = '1' ] && {
		mv "${EXTRACT_DIR}" "${SHARED_SOURCE_ROOT_DIR}/${Package_Source_RootDir}" || {
			error '  Failed to move extracted directory'
			return 5;
		}
		return 0;
	}

	[ ! -e "${EXTRACT_DIR}/${Package_Source_RootDir}" ] && {
		error "  Expected directory '${Package_Source_RootDir}' is not found in extracted files."
		rm -rf "${EXTRACT_DIR}"
		return 6;
	}

	mv "${EXTRACT_DIR}/${Package_Source_RootDir}" "${SHARED_SOURCE_ROOT_DIR}/${Package_Source_RootDir}" || {
		error '  Failed to move extracted directory'
		return 5;
	}

	rm -rf "${EXTRACT_DIR}"
	return 0;
}

BuilderRemove(){
	BuilderInitialize Remove || return ${?};
	mkdir -p "${BUILD_DIR}"
	mkdir -p "${SHARED_SOURCE_ROOT_DIR}"

	vinfo ' Removing...'

	vinfo '  Current architecture'
	rm -rf "${BUILD_DIR}/${Package_Source_RootDir}"
	[ -e "${BUILD_DIR}/${Package_Source_RootDir}" ] && {
		warning '   Failed to remove build directory'
	}

	[ "${ARGS_OPT_LONG_Full:-0}" = '-' ] && {
		ARGS_OPT_LONG_Shared='-';
		ARGS_OPT_LONG_All='-';
	}

	[ "${ARGS_OPT_LONG_All:-0}" = '-' ] && {
		vinfo '  Other architectures'
		for x in ${BUILD_ROOT_DIR}/*-*/${Package_Source_RootDir}; do
			vinfo "   ${x}"
			rm -rf "${x}"
			[ -e "${x}" ] && {
				warning '    Failed to remove build directory'
			}
		done
	}


	[ "${ARGS_OPT_LONG_Shared:-0}" = '-' ] && {
		vinfo '  Shared source files'
		rm -rf "${SHARED_SOURCE_ROOT_DIR}/${Package_Source_RootDir}"
		[ -e "${SHARED_SOURCE_ROOT_DIR}/${Package_Source_RootDir}" ] && {
			warning '   Failed to remove shared source directory'
		}
	}

	return 0;
}

BuilderConfig(){ # mode
	BuilderRunScript Config "${@}" || return ${?};
	return 0;
}

BuilderCompile(){ # mode
	BuilderRunScript Compile "${@}" || return ${?};
	return 0;
}

BuilderInstall(){ # mode
	BuilderRunScript Install "${@}" || return ${?};
	return 0;
}

BuilderClean(){ # mode
	BuilderRunScript Clean "${@}" || return ${?};
	return 0;
}




# Dependency solvers

BuilderSolveDepends_SourceOnly(){ # Mode
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

BuilderSolveDepends_BuildOnly(){ # Build:Y, Install:N, Auto-dev:N, ForBuilder:N
	BuilderSolveDepends 'BuildDepends_BuildOnly' 1 0 0 0 || return ${?};
	return 0;
}

BuilderSolveDepends_BuildTools(){ # Build:Y, Install:Y, Auto-dev:N, ForBuilder:Y
	BuilderSolveDepends 'BuildDepends_BuildTools' 1 1 0 1 || return ${?};

	return 0;
}

BuilderSolveDepends_Library(){ # Build:Y, Install:N, Auto-dev:Y, ForBuilder:N
	BuilderSolveDepends 'BuildDepends_Library' 1 1 1 0 || return ${?};
	BuilderSolveDepends 'BuildDepends_Library' 0 1 0 0 || return ${?};

	BuilderSolveDepends 'Depends' 1 1 1 0 || return ${?};
	BuilderSolveDepends 'Depends' 0 1 0 0 || return ${?};
	return 0;
}

BuilderSolveDepends(){ # Section, F:Build, F:Install, F:AutoDev, InstallTo
	local x;
	local L_SECTION="${1:--}";
	local L_BUILD="${2:-0}";
	local L_INSTALL="${3:-0}";
	local L_AUTODEV="${4:-0}";
	local L_FORBUILDER="${5:-0}";

	local L_DLP_DEFAULT="${DLP_DIR}";
	local L_INSTALL_DEFAULT="${TOOLCHAIN_USR_DIR}";
	[ "${L_FORBUILDER}" = '1' ] && {
		L_DLP_DEFAULT="${DLP_BUILDER_DIR}";
		L_INSTALL_DEFAULT="${TOOLCHAIN_BUILDER_DIR}";
	}

	[ "${L_FORBUILDER}" = '1' ] && {
		L_INSTALL_DEFAULT="${TOOLCHAIN_TOOLS_DIR}";
	}

	local x_ORG;
	local L_ARCH;
	local L_DLP_DIR;
	local L_INSTALL_DIR;

	for x in `ConfigFileList "${PKG_FILE}" "${L_SECTION}"`; do
		L_ARCH='';
		L_DLP_DIR="${L_DLP_DEFAULT}";
		L_INSTALL_DIR="${L_INSTALL_DEFAULT}";

		x_ORG="${x}";
		[ "${L_AUTODEV}" = '1' ] && x="${x}-dev";

		# Prevent loop (Some packages requires builder's arch version of own in building.)
		[ "${L_FORBUILDER}" = '1' ] && [ "${x}" = "${DESL_BUILD_PACKAGE}" ] && [ "${DESL_INTERNAL_TOOLS:-0}" = '1' ] && {
			continue;
		}

		# Directory patch
		case "${x}" in
			bootstrap | bootstrap/* )
				L_DLP_DIR="${DLP_BOOTSTRAP_DIR}";
				L_INSTALL_DIR="${BOOTSTRAP_DIR}";
			;;

			toolchain-base | toolchain-base/* )
				L_DLP_DIR="${DLP_BASEARCH_DIR}";
				L_INSTALL_DIR="${TOOLCHAIN_BASEARCH_DIR}";
			;;

			toolchain | toolchain/* )
				L_DLP_DIR="${DLP_TOOLCHAIN_DIR}";
				L_INSTALL_DIR="${TOOLCHAIN_DIR}";
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

			# Re-check installed (May be installed during build by package has same dependency.)
#			warning "Re-checking: $x in $L_INSTALL_DIR"
#			RunDLPI /Check /Root:${L_INSTALL_DIR} /ID:${x} && {
#				warning "SKIP Already installed: $x in $L_INSTALL_DIR"
#				continue;
#			}

			# Install DLP
			[ "${L_INSTALL}" = '1' ] && {
				RunDLPM /Install /Root:${L_INSTALL_DIR} "${x}" /DLPDir:${L_DLP_DIR} || return ${?}
			}
		}

	done

	return 0;
}
