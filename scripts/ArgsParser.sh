#!INCLUDE_ONLY
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

# ARGS_RAW_STRING	Args string	: "${@}" when called ParseArgs();
# ARGS_OPT_LONG_	Long option	: --long-option(=value)
#			DES option	: /option(:value)
# ARGS_OPT_SHORT_	Short option	: -s(=value)
# ARGS_OPT_N_		+number option	: -n(0)
# ARGS_VALUE_		value override	: key=value
#
# ARGS_FIRST_CMD	mode selector	: First 'ARGS_OPT_LONG_' key that do not have value
# ARGS_TARGET		target selector	: 'make' style target (mode) selector
#					  (First 'ARGS_VALUE_' key that do not have value)

# If value is omitted, will set '-' as value.

ParseArgsKeyConvDB(){
cat <<"EOF";
 	20
!	21
\*	2A
+	2B
,	2C
-	2D
.	2E
\/	2F
:	3A
\?	3F
@	40
EOF
}

ParseArgsKeyEncode(){ # ValNameToReturn, (Key)
	[ "${1}" = '' ] && return 1;
	eval local _KEY_CVT_=\${2:-\${${1}}};
	local _VAL_CVT_=${1};

	local IFS=$'\n\r';
	for x in `ParseArgsKeyConvDB`; do
		IFS=$'\t';
		set -- ${x}
		eval _KEY_CVT_=\${_KEY_CVT_//${1}/__0x${2}__};
	done


	eval ${_VAL_CVT_}=\"${_KEY_CVT_}\";

	return 0;
}

ParseArgsKeyDecode(){ # ValNameToReturn, (Key)
	[ "${1}" = '' ] && return 1;
	eval local _KEY_CVT_=\${2:-\${${1}}};
	local _VAL_CVT_=${1};

	local IFS=$'\n\r';
	for x in `ParseArgsKeyConvDB`; do
		IFS=$'\t';
		set -- ${x}
		eval _KEY_CVT_=\${_KEY_CVT_//__0x${2}__/${1}};
	done

	eval ${_VAL_CVT_}=\"${_KEY_CVT_}\";

	return 0;
}

ParseArgs(){
	local A KEY VAL;
	local OFS=${IFS};
	local IFS=${OFS};
	local LR=$'\n';

	export ARGS_RAW_STRING="${@}";
	export ARGS_TARGET='';
	export ARGS_FIRST_CMD='';
	export ARGS_FIRST_CMD_EX='';
	export ARGS_FILE_LIST='';

	for A in "${@}"; do
		case "${A}" in
			/*:*)
				A="${A:1}";
				K="${A%%:*}";
				V="${A#*:}";
				eval ARGS_OPT_LONG_${K//-/_}="\"${V}\"";
				continue;;

			./* | ../* | /*/* | *://* | ~/* )
				ARGS_FILE_LIST="${ARGS_FILE_LIST:+${ARGS_FILE_LIST}${LR}}${A}";;

			/*)
				A="${A:1}";
				eval ARGS_OPT_LONG_${A//-/_}='-';
				[ "${ARGS_FIRST_CMD}" = '' ] && ARGS_FIRST_CMD=${A};
				[ "${ARGS_FIRST_CMD_EX}" = '' ] && [ "${A:3}" != '' ] && ARGS_FIRST_CMD_EX=${A};
				continue;;

			--*=*)
				A="${A:2}";
				K="${A%%=*}";
				V="${A#*=}";
				eval ARGS_OPT_LONG_${K//-/_}="\"${V}\"";
				continue;;

			--*)
				A="${A:2}";
				eval ARGS_OPT_LONG_${A//-/_}='-';
				[ "${ARGS_FIRST_CMD}" = '' ] && ARGS_FIRST_CMD=${A};
				[ "${ARGS_FIRST_CMD_EX}" = '' ] && [ "${A:3}" != '' ] && ARGS_FIRST_CMD_EX=${A};
				continue;;

			-*=*)
				K="${A:1:1}";
				V="${A:2}";
				eval ARGS_OPT_SHORT_${K//-/_}="\"${V:--}\"";
				continue;;

			-*)
				K="${A:1:1}";
				V="${A:2}";
				eval ARGS_OPT_N_${K//-/_}=${V};
				continue;;

			*=*)
				K="${A%%=*}";
				V="${A#*=}";
				K="${K//-/_}";
				ParseArgsKeyEncode K
				eval ARGS_VALUE_${K}="\"${V}\"";
				continue;;

			*.* | */* )
				ARGS_FILE_LIST="${ARGS_FILE_LIST:+${ARGS_FILE_LIST} }${A}";;

			*)
				ParseArgsKeyEncode A "${A//-/_}"
				eval ARGS_VALUE_${A}='-';

				[ "${ARGS_TARGET}" = '' ] && ARGS_TARGET=${A};
				continue;;
		esac

	done

	[ "${ARGS_TARGET}" = '' ] && ARGS_TARGET="${ARGS_FIRST_CMD}";

	return 0;
}
