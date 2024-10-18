#!INCLUDE_ONLY
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

ExportsInfo(){
cat <<EOF
ARGS_CONFIGURE		=
ARGS_MAKE_CORE			=
ARGS_MAKE_INSTALL		=
BASE_ARCH			=
BASE_ARCH_ARGS			=
BASE_ARCH_BUILD			=
BASE_TARGET			=
BOOTSTRAP_ARCH			=
BOOTSTRAP_ARCH_ORG		=
BOOTSTRAP_ARCH_ORG_T3		=
BOOTSTRAP_BASE_DIR		=
BOOTSTRAP_DIR			=
BOOTSTRAP_ROOT_PREFIX		=
BOOTSTRAP_TARGET		=
BUILD_BOOTSTRAP_DIR		=
BUILD_DIR			=
BUILD_ROOT_DIR			=
BUILDER_ARCH			=
BUILDER_ARCH_BUILD		=
BUILDER_ARCH_BUILD_ORG		=
BUILDER_ARCH_ORG		=
BUILDER_TARGET			=
CORE_ROOTFS_DIR			=
CORETOOLS_DIR			=
CURRENT_BUILD_DIR		=
CURRENT_PACKAGE_DIR		=
DBSE_DIR			=
DEFAULTS_DIR			=
DESL_ARCH			=
DESL_ARCH_BUILD			=
DESL_BUILD_PACKAGE		=
DESL_BUILDER			=
DESL_BUILDER_X			=
DESL_FORCE_STATIC		=
DESL_INTERNAL_TOOLS		=
DESL_OUTPUT_VERBOSE		=
DESL_TARGET			=
DESLB_BUILDING_BOOTSTRAP	=
DESLB_CONFIG_FILE		=
DESLB_NESTLV			=
DESLB_REQUEST_WITHOUT_FSV	=
DESLB_SESSION_DIR		=
DESLB_SESSION_ID		=
DESLB_SH			=
DESLB_SKIP_PREREQ		=
DESLB_STARTUP_PATH		=
DESLB_STATIC			=
DL_CACHE_DIR			=
DLP_BASEARCH_DIR		=
DLP_BOOTSTRAP_DIR		=
DLP_BUILDER_DIR			=
DLP_DIR				=
DLP_INSTALL_DIR			=
DLP_MAKE_ROOT_DIR		=
DLP_TOOLCHAIN_DIR		=
ETC_DIR				=
IMAGE_BOOTSTRAP_DIR		=
IMAGE_DIR			=
IMAGE_ROOT_DIR			=
IMPORT_BUILD_DIR		=
INCLUDES_DIR			=
PACKAGE_ROOT_CATEGORY		=
PACKAGES_DIR			=
ROOT_DIR			=
ROOTFS_DIR			=
SCRIPTS_DIR			=
SHARED_BUILD_DIR		=
SHARED_SOURCE_DIR		=
SHARED_SOURCE_ROOT_DIR		=
TOOLCHAIN_BASE_DIR		=
TOOLCHAIN_BASEARCH_DIR		=
TOOLCHAIN_BUILDER_DIR		=
TOOLCHAIN_DIR			=
TOOLCHAIN_LOCAL_DIR		=
TOOLCHAIN_ROOT_DIR		=
TOOLCHAIN_TOOLS_CORE_DIR	=
TOOLCHAIN_TOOLS_DIR		=
TOOLCHAIN_USER_BASE_DIR		=
TOOLCHAIN_USR_DIR		=
W_BOOTSTRAP_DIR			=
W_DES_TARGET			=
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
			echo -e "\e[36;1m${K}\e[m\e[1m: \e[32;1m${V}\e[m"
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
