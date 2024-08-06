#!INCLUDE_ONLY
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

RunCheckPrerequisites(){
	[ "${DESLB_BUILDING_BOOTSTRAP:+1}" = '1' ] && {
		CheckPrerequisites_Bootstrap
		return ${?};
	}

	# CheckPrerequisites_Toolchain

	return 0;
}

CheckPrerequisites_Bootstrap(){

	# 'MakeCPIO' ('dlpm' cannot use at this point)
	[ ! -e "${BOOTSTRAP_DIR}/bin/MakeCPIO" ] && {
		RunDESLBuilder /Package:bootstrap/MakeCPIO /M:/Build || return ${?};
	}

	return 0;
}
