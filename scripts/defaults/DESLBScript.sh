#!INCLUDE_ONLY
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

DESLB_SUPPORT_NATIVE_ISOLATION=1
DESLB_SKIP_CONFIG_IF_EXISTS=Makefile

# DSH_ functions are defined in DESLBScript_Helper

DESLBInitialize(){
	:
}

DESLBFinalize(){
	:
}

DESLBConfig(){
	DSH_configure || return ${?};
	return 0;
}

DESLBCompile(){
	DSH_make || return ${?};
	return 0;
}

DESLBInstall(){
	DSH_makeInstall || return ${?};
	return 0;
}

DESLBClean(){
	DSH_make clean
	return 0;
}
