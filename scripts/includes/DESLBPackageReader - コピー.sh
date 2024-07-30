#!INCLUDE_ONLYhy
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

PackageInfo(){
cat <<EOF
Package_Category		Category ID
Package_Name			User-friendly package name
Package_ID_Full			Final package ID (Use as DLP file name)
Package_ID			Package ID
Package_Revision		Revision number in same version
Package_Source_BaseURI		Source download URL (Base)
Package_Source_BaseURI_RAW	Source download URL (Base, RAW)
Package_Source_File		Full remote file name of source
Package_Source_FileName		Remote file name of source
Package_Source_FileName_RAW	Remote file name of source (RAW)
Package_Source_FileExts		Remote file name extensions of source
Package_Source_RootDir		Root directory in source archive
Package_Source_RootDir_RAW	Root directory in source archive (RAW)
Package_Version			Package version
EOF
}


PackageSanitize(){ # VAL
	# This is minimum, only intended use in DESLBuilder SSE
	# It is also always build by a non root user

	local "K=${1}";
	eval local V="\${${1}}";

	V="${V/\(/[}";
	V="${V/\)/]}";
	V="${V/\`/\'}";

	eval ${K}=\"${V}\";
}

PackageLoad(){ # PackageID, PackageDef, [Prefix]
	local PACKAGE_ID="${1}";
	local PACKAGE_DEF_FILE="${2}";
	local VAL_PREFIX="${3}";

	[ ! -e "${PACKAGE_DEF_FILE}" ] && {
		error "Package '${PACKAGE_DEF_FILE}' is not  found."
		return 1;
	}

	ConfigLoad "${PACKAGE_DEF_FILE}" DESLPackage > /dev/null

	Package_ID="${PACKAGE_ID%%/*}";
	Package_Category="${PACKAGE_ID#*/}";

	ConfigGet Package_Name DESLPackage::DESLPackage:Name -
	ConfigGet Package_Version DESLPackage::DESLPackage:Version 0
	ConfigGet Package_Revision DESLPackage::DESLPackage:Revision 0

	ConfigGet Package_Source_BaseURI_RAW DESLPackage::Source:BaseURI -
	ConfigGet Package_Source_FileName_RAW DESLPackage::Source:FileName ''
	ConfigGet Package_Source_FileExts DESLPackage::Source:FileExts -
	ConfigGet Package_Source_RootDir_RAW DESLPackage::Source:RootDir ''
	ConfigGet Package_Source_SaveTo_RAW DESLPackage::Source:SaveTo ''
	ConfigGet Package_Source_MakeDir DESLPackage::Source:MakeDir '0'

	PackageSanitize Package_Source_BaseURI_RAW
	PackageSanitize Package_Source_FileName_RAW
	PackageSanitize Package_Source_RootDir_RAW
	PackageSanitize Package_Source_SaveTo_RAW

	eval Package_Source_BaseURI=\"${Package_Source_BaseURI_RAW}\"
	eval Package_Source_FileName=\"${Package_Source_FileName_RAW}\"
	eval Package_Source_RootDir=\"${Package_Source_RootDir_RAW}\"
	eval Package_Source_SaveTo=\"${Package_Source_SaveTo_RAW}\"

	Package_Source_File="${Package_Source_FileName}${Package_Source_FileExts}";

	Package_Source_SaveTo="${Package_Source_SaveTo:-${Package_Source_File}}";

	[ "${Package_Source_RootDir_RAW}" = '' ] && {
		Package_Source_RootDir_RAW="${Package_Source_FileName:-${PACKAGE_ID//\//_}}";
		Package_Source_RootDir="${Package_Source_RootDir_RAW}";
	}

	Package_ID_Full="${Package_Category}/${Package_Name}_${Package_Version}-${Package_Revision}";

	ConfigGet Package_Source_SHA256 DESLPackage::Source:SHA256 -

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

PackageDump(){
	PackageLoad "${DESL_BUILD_PACKAGE}" "${PACKAGES_DIR}/${DESL_BUILD_PACKAGE}/DESLPackage.def";
	local IFS=$'\n\r';
	local K V;

	for x in `PackageInfo`; do
		IFS='	';
		set -- ${x};
		K="${1}";
		eval V=\$\{${K}\};
		shift;
		echo "${K}=${V}"
	done
	return 0;
}
