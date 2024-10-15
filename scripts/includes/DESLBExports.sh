#!INCLUDE_ONLY
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

ExportsInfo(){
cat <<EOF
BUILDER_ARCH			Detected architecture for bootstrap toolchain
BUILDER_ARCH_BUILD		Detected architecture for bootstrap toolchain (for build scripts)
BUILDER_ARCH_BUILD_ORG	Detected architecture for bootstrap toolchain (Unmodified)
BOOTSTRAP_DIR			Directory of bootstrap toolchain
BOOTSTRAP_ROOT_PREFIX		Prefix for bootstrap toolchains (BOOTSTRAP_DIR)
BOOTSTRAP_TARGET		Bootstrap triplet for configure
BOOTSTRAP_TARGET_ORG		Bootstrap triplet for configure (Unmodified)
BOOTSTRAP_W_DIR			Directory of bootstrap toolchain (win32)
BOOTSTRAP_ARCH			Detected architecture of current machine
BOOTSTRAP_ARCH_ORG		Detected architecture of current machine (Unmodified)
BOOTSTRAP_ARCH_ORG_T3		Detected system type of current machine
BUILD_DIR			Directory for building apps
BUILD_BOOTSTRAP_DIR		Directory for building bootstrap toolchains
BUILD_ROOT_DIR			Root directory for building
CORETOOLS_DIR			Directory of core tools
CORE_ROOTFS_DIR			Root directory of DESLinux boot image (RAM)
DBSE_DIR			Directory of DESLBuilder Script Engine
DESLB_CONFIG_FILE		DESLBuilder configuration file (.config)
DESLB_ENV_CHECKED		If not 0: Passed startup environmental testing
DESLB_HAS_SESSION		If not 0: Valid session ID assigned
DESLB_RUN_AS_ROOT		Running DESLBuilder as (v)root
DESLB_RUN_IN_WORLD		Running DESLBuilder in virtualized filesystem
DESLB_SESSION_DIR		Session Directory will remove when DESLBuilder exits
DESLB_SESSION_ID		Session ID
DESLB_SH			Path of DESLBuilder internal shell
DESL_ARCH			DESLinux Target architecture
DESL_ARCH_BUILD			DESLinux Target architecture for standard build scripts
DESL_ARCH_BUILD_BASE		DESLinux Target architecture, Detailed (Main)
DESL_ARCH_BUILD_SUB		DESLinux Target architecture, Detailed (Sub)
DESL_BUILDER			Path of DESLBuilder
DESL_BUILDER_X			If not 0: DESLBuilder type is X
DESL_BUILD_PACKAGE		?
DESL_FORCE_STATIC		DESLBuilder requests static linking
DESL_INTERNAL_TOOLS		If not 0: Now building internal tools
DESL_OUTPUT_VERBOSE		If not 0: User requested verbose output
DESL_TARGET			DESLinux target triplet
DES_W_TARGET			DESLinux target triplet (win32)
DLP_BOOTSTRAP_DIR		Directory of .dlp files for bootstrap toolchains
DLP_DEST_DIR			Directory for 'DESTDIR=' option in 'Makefile'
DLP_DIR				Directory of .dlp files
DLP_INSTALL_DIR			Files in this directory will include in DLP
DLP_PREFIX_DIR			Directory for '--prefix=' option in 'configure'
DL_CACHE_DIR			Directory of DESLBuilder download cache
ETC_DIR				Directory of DESLBuilder support files
IMAGE_BOOTSTRAP_DIR		Directory of bootstrap build results
IMAGE_DIR			Directory of build results
IMAGE_ROOT_DIR			Root directory of IMAGE_DIR
INCLUDES_DIR			Directory of DESLBuilder inlcludes
MAKE_OPT			Option arguments from 'make' command
OLDPWD				PATH from environment (Use only in building bootstrap toolchains)
PACKAGES_DIR			Directory of package definitions
PACKAGE_ROOT_CATEGORY		Category of current package
ROOTFS_DIR			Root directory of installed DESLinux system
ROOT_DIR			Root directory of DESLinux Builder
SCRIPTS_DIR			Directory of DESLBuilder scripts
SHARED_SOURCE_ROOT_DIR		Directory of source extraction that supports shared building
TOOLCHAIN_BASE_DIR		Directory for toolchains of current system
TOOLCHAIN_DIR			Directory of current toolchain
TOOLCHAIN_LOCAL_DIR		Directory for not managed by DLPM
TOOLCHAIN_ROOT_DIR		Root directory of toolchains
TOOLCHAIN_TOOLS_DIR		Directory for build support tools
TOOLCHAIN_USER_BASE_DIR		Root directory of installed DLPs for toolchain
TOOLCHAIN_USR_DIR		Directory of installed DLPs for toolchain
EOF
}

ShowExports(){
	local IFS=$'\n\r';
	local K V;

	[ ! "${DESL_OUTPUT_VERBOSE:-0}" = '0' ] && {
		for x in `ExportsInfo`; do
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

	for x in `ExportsInfo`; do
		IFS='	';
		set -- ${x};
		K="${1}";
		eval V=\$\{${K}\};
		shift;
		echo "${K}: ${V}"
	done
	return 0;

}
