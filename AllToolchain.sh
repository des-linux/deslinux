#!/bin/sh

main(){
	local SELF="${BASH_SOURCE:-${0}}";
		
	SELF=`readlink -f "${SELF}" || echo "${SELF}"`;
	local sRoot="${SELF%/*}";

	for x in ${sRoot}/toolchain/builder-x86/desl-*/bin; do
		export PATH=$x:$PATH;
	done

	[ "${BASH_SOURCE}" = '' ] && {
		${sRoot}/toolchain/bootstrap-x64/DBSE/busybox ash
	}
		
}

main "${@}"
