#!INCLUDE_ONLY
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

DESLBAM(){
	local R=0;

	# Check base arch is installed
	local BASE_ARCH="${ARCH_ARGS%%,*}";
	BASE_ARCH="${BASE_ARCH// /}";
	BASE_ARCH_DIR="${TOOLCHAIN_BASE_DIR}/base-${BASE_ARCH}";

	error OKOK: $BASE_ARCH_DIR
	error $ARGS_OPT_LONG_Arch

	return 0;
}
