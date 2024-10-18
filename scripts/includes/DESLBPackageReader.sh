#!INCLUDE_ONLY
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

DESLBPACKAGEREADER_DESLPACKAGE='Redirect ImportCoreInfo Category ID ID_Suffix ID_Full Name Version Revision';
DESLBPACKAGEREADER_SOURCE='BaseURI_RAW FilaName_RAW RootDir_RAW SaveTo_RAW MakeDir SHA256 BaseURI FileExts FileName RootDir SaveTo File';

PackageInfo(){
cat <<EOF
Package_Category		Category ID
Package_Name			User-friendly package name
Package_ID			Package ID
Package_ID_Full			Final package ID (Use as DLP file name)
Package_ID_Suffix
Package_Redirect
Package_Revision		Revision number in same version
Package_Version			Package version
Package_Source_BaseURI		Source download URL (Base)
Package_Source_BaseURI_RAW	Source download URL (Base, RAW)
Package_Source_File		Full remote file name of source
Package_Source_FileName		Remote file name of source
Package_Source_FileName_RAW	Remote file name of source (RAW)
Package_Source_FileExts		Remote file name extensions of source
Package_Source_RootDir		Root directory in source archive
Package_Source_RootDir_RAW	Root directory in source archive (RAW)
Package_Source_MakeDir
Package_Source_SHA256
Package_Source_SaveTo
Package_Source_SaveTo_RAW
EOF
}

PackageReplace(){ # VAL
	local x;
	local "K=${1}";
	eval local V="\${${1}}";

	# [DESLPackage] section
	# V="${V/$\{Name\}/${Package_Name}}";
	# V="${V/$\{Version\}/${Package_Version}}";
	# V="${V/$\{Revision\}/${Package_Revision}}";
	for x in ${DESLBPACKAGEREADER_DESLPACKAGE}; do
		eval V="\${V/\$\{${x}\}/\${Package_${x}}}";
	done

	# V="${V/$\{FileExts\}/${Package_Source_FileExts}}";
	for x in ${DESLBPACKAGEREADER_SOURCE}; do
		eval V="\${V/\$\{${x}\}/\${Package_Source_${x}}}";
	done

	eval ${K}=\'${V}\';
}

PackageLoad(){ # PackageID, PackageDef, [Prefix]
	local PACKAGE_ID="${1}";
	local PACKAGE_DEF_FILE="${2}";
	local VAL_PREFIX="${3}";
	local x R;

	[ ! -e "${PACKAGE_DEF_FILE}" ] && {
		error "Package '${PACKAGE_DEF_FILE}' is not defined."
		return 1;
	}

	R=`PackageRead "${PACKAGE_ID}" "${PACKAGE_DEF_FILE}"` || return ${?};

	for x in ${R}; do
		eval local local_${x}
		eval ${VAL_PREFIX:+${VAL_PREFIX}_}${x}
	done

	[ ! "${local_Package_ImportCoreInfo:--}" = '-' ] && {
		local PACKAGE_COREINFO_FILE="${PACKAGES_DIR}/${local_Package_ImportCoreInfo}/DESLPackage.def";
		R=`PackageRead "${local_Package_ImportCoreInfo}" "${PACKAGE_COREINFO_FILE}"` || return ${?};
		for x in ${R}; do
			eval local cic_${x};
		done
		eval ${VAL_PREFIX:+${VAL_PREFIX}_}Package_Version="${cic_Package_Version}";
		eval ${VAL_PREFIX:+${VAL_PREFIX}_}Package_ID_Suffix="${cic_Package_Version}-${local_Package_Revision}";
	}

	return 0;
}

PackageRead(){ # PackageID, PackageDef
	local PACKAGE_ID="${1}";
	local PACKAGE_DEF_FILE="${2}";
	local x;

	[ ! -e "${PACKAGE_DEF_FILE}" ] && {
		error "Package '${PACKAGE_DEF_FILE}' is not defined."
		return 1;
	}

	ConfigLoad "${PACKAGE_DEF_FILE}" DESLPackage > /dev/null || return ${?};

	# Core
	Package_Category="${PACKAGE_ID%/*}";
	Package_ID="${PACKAGE_ID##*/}";

	# [DESLPackage] section
	ConfigGet Package_Name DESLPackage::DESLPackage:Name -
	ConfigGet Package_Version DESLPackage::DESLPackage:Version 0
	ConfigGet Package_Revision DESLPackage::DESLPackage:Revision 0
	ConfigGet Package_ImportCoreInfo DESLPackage::DESLPackage:ImportCoreInfo -
	ConfigGet Package_Redirect DESLPackage::DESLPackage:Redirect -

	# [Source] section
	for x in ${DESLBPACKAGEREADER_SOURCE}; do
		ConfigGet Package_Source_${x} DESLPackage::Source:${x} ''
		PackageReplace Package_Source_${x}
	done

	# Generated
	Package_ID_Suffix="${Package_Version}-${Package_Revision}";
	Package_ID_Full="${Package_Category}/${Package_ID}_${Package_ID_Suffix}";
	Package_Source_File="${Package_Source_FileName}${Package_Source_FileExts}";

	# Generate if not defined
	[ "${Package_Source_RootDir}" = '' ] && {
		Package_Source_RootDir="${Package_Source_FileName:-${PACKAGE_ID//\//_}}";
	}

	[ "${Package_Source_SaveTo}" = '' ] && {
		Package_Source_SaveTo="${Package_Source_FileName}${Package_Source_FileExts}";
	}


	for x in ${DESLBPACKAGEREADER_DESLPACKAGE}; do
		eval echo "Package_${x}=\'\${Package_${x}}\'";
	done

	for x in ${DESLBPACKAGEREADER_SOURCE}; do
		eval echo "Package_Source_${x}=\'\${Package_Source_${x}}\'";
	done

	return 0;
}

PackageGetInfo(){
	PackageLoad "${DESL_BUILD_PACKAGE}" "${PACKAGES_DIR}/${DESL_BUILD_PACKAGE}/DESLPackage.def";

	local IFS=$'\n\r';
	local K V;

	[ ! "${DESL_OUTPUT_VERBOSE:-0}" = '0' ] && {
		for x in `PackageInfo`; do
			IFS='	';
			set -- ${x};
			K="${1}";
			eval V=\$\{${K}\};
			shift;
			echo -e "\e[36;1m${K}\e[m\e[32;1m: ${V}\e[m"
			echo -e "	\e[1m${*}\e[m"
			echo
		done
		return 0;
	}

	for x in `PackageInfo`; do
		IFS='	';
		set -- ${x};
		K="${1}";
		eval V=\$\{${K}\};
		shift;
		echo "${K}: ${V}"
	done
	return 0;
}
