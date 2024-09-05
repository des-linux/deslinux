#!INCLUDE_ONLY
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

DESLB_SUPPORT_NATIVE_ISOLATION=0
DESLB_SKIP_CONFIG_IF_EXISTS=Makefile

DESLBInitialize(){
	:
}

DESLBFinalize(){
	:
}

DESLBConfig(){
	[ "${DESLB_SUPPORT_NATIVE_ISOLATION:-0}" = '1' ] && {
		"${SHARED_SOURCE_DIR}/configure"
		return ${?};
	}

	error ./configure --host=${DESL_TARGET}
	return 3
	return ${?};
}

DESLBCompile(){
	${DESL_MAKE}
	return ${?};
}

DESLBInstall(){
	${DESL_MAKE} install DESTDIR="${DLP_INSTALL_DIR}" prefix='/'
	return ${?};
}

DESLBClean(){
	make clean
	return ${?};
}
