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
	ExportToolchainInfo

	[ "${DESLB_SUPPORT_NATIVE_ISOLATION:-0}" = '1' ] && {
		"${SHARED_SOURCE_DIR}/configure" --build=${BUILDER_TARGET} --host=${DESL_TARGET}
		return ${?};
	}

	./configure --build=${BUILDER_TARGET} --host=${DESL_TARGET}
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
