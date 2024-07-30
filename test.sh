#!/bin/sh

CheckEmptyDir(){
	local P="${1}";
	set -- ${1}/*
	[ "${P}/*" = "${1}" ] && return 0;
	return 1;
}
