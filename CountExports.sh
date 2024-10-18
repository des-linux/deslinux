#!/bin/ash

main(){
	local x;

	for x in `DumpExportsList`; do
		FindAtLeastOne "${x}"
	done
	return 0;
}

DumpExportsList(){
	. ./scripts/includes/DevTools_DESLBExports.sh

	local x;
	local IFS=$'\n\r';
	for x in `ExportsInfo`; do
		echo "${x%%	*}"
	done

	return 0;
}

CountLine(){ # file, match
	local x;
	local n;
	local IFS=$'\n\r';
	for x in `cat "${1}" | grep -v "export ${2}=" | grep -e "${2}"`; do
		n=$((n+1));
	done

	return ${n};
}

FindAtLeastOne(){
	local x;
	local N=0;
	local R=0;

	CountLine ./DESLBuilder "${1}"
	R=${?};
	N=$((N+R));

	for x in `find ./scripts -type f`; do
		case "${x}" in
			*/MakeCPIO |\
			*/x86test |\
			*/DevTools_DESLBExports.sh )
				continue;;
		esac

		CountLine "${x}" "${1}"
		R=${?};
		N=$((N+R));
	done

	for x in `find ./packages -type f -name "DESLBScript.sh"`; do
		CountLine "${x}" "${1}"
		R=${?};
		N=$((N+R));
	done


	[ "${N}" = '0' ] && {
		error "${1}: ${N}"
		return 1;
	}

	[ "${N}" -lt '5' ] && {
		warning "${1}: ${N}"
	} || {
		: infoex "${1}: ${N}"
	}
	return 0;
}

error(){
	echo -e "\e[31;1mE:\e[m\e[1m ${*}\e[m" >&2
}
warning(){
	echo -e "\e[33;1mW:\e[m\e[1m ${*}\e[m" >&2
}
infoex(){
	echo -e "\e[m\e[1mI:\e[m\e[1m ${*}\e[m"
}
info(){
	echo -e "I: ${*}"
}

main "${@}"
