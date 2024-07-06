#!INCLUDE_ONLY
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

DESLB_SUPPORT_NATIVE_ISOLATION=0

DESLBInitialize(){
	:
}

DESLBFinalize(){
	:
}

DESLBConfig(){
	./configure
}

DESLBCompile(){
	make
}

DESLBInstall(){
	make install
}
