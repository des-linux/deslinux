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

BuilderInitialize(){
	infoex "[${DESLB_NESTLV}] ${DESL_BUILD_PACKAGE}: ${1}"
	PKG_FILE="${PACKAGES_DIR}/${DESL_BUILD_PACKAGE}/DESLPackage.def";
	PackageLoad "${DESL_BUILD_PACKAGE}" "${PKG_FILE}";
	return ${?};
}

BuilderRunScript(){
	BuilderInitialize "${1}"

	BuilderSolveLibraryDepends || return ${?};
	BuilderSolveHostToolsDepends || return ${?};

	BuilderRunScriptEx unshare -m "${DESLB_SH}" "${SCRIPTS_DIR}/ExecBuildScript" "${@}" || return ${?};
	return ${?};
}

# [Depends]			= BuildDepends_Library (+ '-dev' package) & RuntimeDepends
# [BuildDepends_SourceOnly]	/Download, /Extract
# [BuildDepends_Library]	RunScripts
# [BuildDepends_HostTools]	RunScripts
# [RuntimeDepends]		dlpm

BuilderSolveSourceDepends(){
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

BuilderSolveLibraryDepends(){
	local x;
	for x in `ConfigFileList "${PKG_FILE}" 'BuildDepends_Library'`; do
		local INSTALL_DIR="${TOOLCHAIN_USR_DIR}";
		vinfo "Checking install status of library..."

		BuilderDLPM_Library /Install "${x}-dev" "${x}" || return ${?};
		BuilderDLPM_Library /Install "${x}" 1
	done
	return 0;
}

BuilderSolveHostToolsDepends(){
	local x;

	for x in `ConfigFileList "${PKG_FILE}" 'BuildDepends_HostTools'`; do
		local INSTALL_DIR="${TOOLCHAIN_TOOLS_DIR}";
		vinfo "Checking install status of host tools..."

		BuilderDLPM_Tools /Install "${x}" || return ${?};
	done

	return 0;
}

BuilderDownload(){
	BuilderInitialize Download || return ${?};

	BuilderSolveSourceDepends /Download || return ${?};

	vinfo ' Downloading...'
	[ "${Package_Source_SaveTo}" = '' ] && {
		vinfo '  No source file required'
		return 0;
	}

	local PKG_ARC_FILE="${DL_CACHE_DIR}/${Package_Source_SaveTo}"

	[ -e "${PKG_ARC_FILE}" ] && {
		vinfo '  Already downloaded'
		return 0;
	}

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

	BuilderSolveSourceDepends /Extract || return ${?};

	mkdir -p "${BUILD_DIR}"
	mkdir -p "${SHARED_SOURCE_ROOT_DIR}"

	vinfo ' Extracting...'
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

BuilderDLPM_Library(){ # Mode, PackageID, DoNotBuildIfNotFound
	local INSTALL_DIR="${TOOLCHAIN_USR_DIR}";
	BuilderDLPM "${INSTALL_DIR}" "${@}"
	return ${?};
}

BuilderDLPM_Tools(){ # Mode, PackageID, DoNotBuildIfNotFound
	local INSTALL_DIR="${TOOLCHAIN_TOOLS_DIR}";
	BuilderDLPM "${INSTALL_DIR}" "${@}"
	return ${?};
}

BuilderDLPM(){ # Path, Mode, PackageID, DoNotBuildIfNotFound
	local INSTALL_DIR="${1}";
	local MODE="${2}";
	local PID="${3}";
	local BIFN="${4}";

	case "${PID}" in
		bootstrap/* )
			INSTALL_DIR="${BOOTSTRAP_DIR}";;
		toolchain-base/* )
			INSTALL_DIR="${BASE_TOOLCHAIN_DIR}";;
		toolchain/*)
			INSTALL_DIR="${TOOLCHAIN_DIR}";;
	esac

	case "${MODE}" in
		/Install )
			BuilderDLPMInstall "${INSTALL_DIR}" "${PID}" "${BIFN}"
			return ${?};;
		/Remove )
			BuilderDLPMRemove "${INSTALL_DIR}" "${PID}"
			return ${?};;
	esac
	error 'Unsupported mode '${MODE}' specified.'
	return 1;
}

BuilderDLPMInstall(){ # Path, PackageID, DoNotBuildIfNotFound
	local INSTALL_DIR="${1}";
	local PID="${2}";
	local BIFN="${3}";

	# If not installed
	RunDLPI /Check /Root:${INSTALL_DIR} /ID:${PID} || {

		# If package is not found
		RunDLPM /FindPackage "${PID}" /Quiet || {
			[ "${BIFN:-0}" = '1' ] && {
				return 251;
			}

			local BID="${PID}";
			case "${BID}" in
				*-dev | *-doc )
					BID="${BID%-*}";
				;;
			esac

			RunDESLBuilder ${ARGS_RAW_STRING} /M:/Build /Package:${BID} || return ${?}
		}

		# install
		RunDLPM /Install /Root:${INSTALL_DIR} "${PID}" || return ${?}
	}

	# Installed just / already
	return 0;
}

BuilderDLPMRemove(){ # Path, PackageID
	local INSTALL_DIR="${1}";
	local PID="${2}";

	# If installed
	RunDLPI /Check /Root:${INSTALL_DIR} /ID:${PID} && {
		# Remove
		RunDLPM /Remove /Root:${INSTALL_DIR} "${PID}" || return ${?}
	}

	# Removed just / already
	return 0;
}
