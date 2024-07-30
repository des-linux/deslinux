#!INCLUDE_ONLY
#//////////////////////////////////////////////////
#//DESLinux Builder
#//	(C)2014-2022 Dark Embedded Systems.
#//	http://xprj.net/
#//////////////////////////////////////////////////

ConfigGetEnv(){
	CONFIGMANEGER_ESCAPE_0x3A='_____Key_0x3A______';
	NAMESPACE_DIV='_____DC_NS_____';
	GROUP_DIV='_____DC_GRP_____';
	KEY_PFX='_';
	return 0;
}


ConfigFileFormat(){ # Path
	[ "${1}" != '-' ] && {
		[ ! -f "${1}" ] && {
			return 1;
		}
	}

	local IFS='';
	set -f

	# Escape '[' to prevent to search file
	local CONFIG=`cat ${1}`;


	local KEY;
	IFS=$'\n\r';
	for l in ${CONFIG}; do
		unset VAL;
		case "${l}" in
			*=*	) # Strip blank char
				IFS=$' \t'
				set -- ${l%%=*}; KEY="${*}";
				set -- ${l#*=}; VAL="${*}";
			;;
			*	) # Strip blank
				IFS=$' \t';
				set -- ${l}; KEY="${*}";
			;;
		esac

		[ "${KEY:0:1}" = '#' ] && continue
		[ "${KEY:0:2}" = '//' ] && continue

		echo "${KEY}${VAL:+=${VAL}}"
	done

	set +f
	return 0;
}

ConfigFileGroup(){ # Path
	local GRP;
	local IFS=$'\n\r';
	for l in `ConfigFileFormat "${1}"`; do
		[ "${l:0:1}" = '[' ] && {
			GRP=${l:1};
			echo ${GRP%]}
		}
	done
	return 0;
}

ConfigFileList(){ # Path (Group)
	local SHOW;
	local IFS=$'\n\r';
	SHOW=0;

	set -f
	[ "${2}" = '' ] && {
		local GRP;
		for l in `ConfigFileFormat "${1}"`; do
			IFS=$' \t';
			[ "${l:0:1}" = '[' ] && {
				GRP=${l:1}
				continue
			}
			echo "${GRP:+${GRP%]}:}${l}"
		done
	} || {
		for l in `ConfigFileFormat "${1}"`; do
			IFS=$' \t';
			[ "${l:0:1}" = '[' ] && SHOW=0;
			[ "${SHOW}" = '1' ] && echo "${l}"
			[ "${l}" = "[${2}]" ] && SHOW=1;
		done
	}

	set +f
	return 0;
}

ConfigGet(){ # ValNameToReturn, (FullKey), (DefaultValue)
	[ "${1}" = '' ] && return 1;
	eval local _KEY_=\${2:-\${${1}}};

	local _VN_=${1};

	ConfigKey2Env _KEY_ || return 1;
	eval local _V_=\${${_KEY_}/\\\`/};
	[ "${_V_}" = '' ] && {
		[ "${3}" = '' ] && {
			eval ${_VN_}=\'\';
		} || {
			_V_="${3}";
			eval ${_VN_}=\'${_V_}\';
		}
		return 1;
	}

	eval ${_VN_}=\'${_V_}\';
	return 0;
}

ConfigSet(){ # FullKey Value
	[ "${1}" = '' ] && return 1;
	local _KEY_=${1};

	ConfigKey2Env _KEY_ || return 1;
	eval ${_KEY_}=${2};
	return 0;
}

ConfigDelete(){ # FullKey
	[ "${1}" = '' ] && return 1;
	local _KEY_=${1};

	ConfigKey2Env _KEY_ || return 1;
	unset ${_KEY_};
	return 0;
}

ConfigDeleteGroup(){ # (Namespace::)Group
	[ "${1}" = '' ] && return 1;
	local _GRP_=${1};

	for v in `CONFIG_SHOW_NAMESPACE=1 ConfigList "${_GRP_}"`; do
		ConfigDelete "${v}";
	done
	return 0;
}

ConfigLoad(){ # Path, (Namespace)
	ConfigUnload ${2}
	ConfigMerge "${@}"
	return ${?};
}

ConfigUnload(){ # (Namespace)
	local V;
	local NS=${1};
	local IFS;

	case "${NS}" in
		'@' | '*') NS='';; # Remove all namespaces
		*::	) ;;
		*	) NS=${NS}::;
	esac

	ConfigKey2Env NS

	local IFS=$'\n\r';
	for v in `set`; do
		case "${v}" in
			${NS}*	)
				unset ${v%=*}
			;;
		esac
	done
	return 0;
}

ConfigMerge(){ # Path (Namespace)
	echo "I:  Loading \"${1}\"..."

	[ "${1}" != '-' ] && {
		[ ! -f "${1}" ] && {
		echo "W: File \"${1}\" not found."
			return 1;
		}
	}

	local GRP OGRP KEY N;
	local NS=${2};
	case "${NS}" in
		*::	) ;;
		*	) NS=${NS}::;
	esac

	local IFS='';
	local CONFIG=`ConfigFileFormat "${1}"`;
	CONFIG=${CONFIG//[/\\[};

	local VAL;
	IFS=$'\n\r';
	for l in ${CONFIG}; do

		[ "${l:0:2}" = "\\[" ] && {
			GRP=${l:2}
			GRP=${GRP%]}
			OGRP=${GRP};

			# Strip blank char
			IFS=$'\t ';
			set -- ${GRP}; GRP=${*};
			set -- ${OGRP}; OGRP=${*};

			eval local _DC_CNT_${OGRP};
#			eval GRP=${GRP}\${_DC_CNT_${OGRP}};
			eval GRP=${GRP}\${_DC_CNT_${OGRP}:+_\${_DC_CNT_${OGRP}}}
			eval _DC_CNT_${OGRP}=$((_DC_CNT_${OGRP}+1));

			echo "I:   Loading group: ${GRP}..."
			continue
		}

		# Skip no '='
		case "${l}" in
			*=*	) ;;
			*	) continue;;
		esac

		KEY=${l%%=*};
		KEY=${NS}${GRP:+${GRP}:${KEY//:/${CONFIGMANEGER_ESCAPE_0x3A}}};
		VAL=${l#*=};

		ConfigKey2Env KEY
		VAL="${VAL//\$/\\$}";
		VAL="${VAL//\\[/[}";
		VAL="${VAL//\`/}";
		eval ${KEY}="\"${VAL}\"";
	done

	set | grep Override

	return 0
}

ConfigSave(){ # Path, (Namespace)
	local FILE=${1};
	local NS=${2};
	[ "${FILE}" = '' ] && echo "W: ConfigSave: File path not specified." && return 1;

	case "${NS}" in
		*::	) ;;
		*	) NS=${NS}::;
	esac

	: > ${FILE}

	local GRP _OldGRP_;

	local IFS=$'\n\r';
	for l in `ConfigListWithValue ${NS}`; do
		case "${l}" in
			*:*	)
				GRP=${l%%:*};
				[ "${_OldGRP_}" != "${GRP}" ] && {
					echo >> ${FILE}
					echo "[${GRP}]" >> ${FILE}
				}

				_OldGRP_=${GRP};
			;;
		esac

		echo "${l#*:}" >> ${FILE}
	done
	return 0;
}

ConfigSearch(){ # ((Namespace::)(Group:)Key)
	local OFS=${IFS};
	local IFS NS QRY;

	local V KEY;
	local QRY=${1};
	local IFS=$'\n\r';

	local RemoveNS='::';
	[ "${CONFIG_SHOW_NAMESPACE:-1}" = '1' ] && RemoveNS='\\';
	[ "${CONFIG_HIDE_GROUP:-0}" = '1' ] && RemoveNS='*:';

	case "${QRY}" in
		*:* | '') ;;
		*	) QRY=::${QRY};;
	esac

	ConfigKey2Env QRY || return 1;
	[ "${CONFIG_SHOW_VALUE:-0}" = '1' ] && {
		for v in `set`; do
			case "${v}" in
				${QRY}*=\'*\' )
					IFS=$'=';
					set -- ${v}
					KEY=${1};
					shift
					V=${*};
					V=${V:1};
					V=${V%\'};
					ConfigEnv2Key KEY
					echo "${KEY##*${RemoveNS}}=${V}";
				;;
				${QRY}* )
					ConfigEnv2Key v
					echo "${v##*${RemoveNS}}";
				;;
			esac
		done
	} || {
		for v in `set`; do
			case "${v}" in
				${QRY}* )
					v=${v%%=*};
					ConfigEnv2Key v
					echo "${v##*${RemoveNS}}";
				;;
			esac
		done
	}
	return 0;
}

ConfigSearchEx(){ # ((Namespace::)(Group:)Key), (Divider)
	return 0;
}

ConfigList(){ # ((Namespace::)Group)
	local GRP=${1};
	local IFS=$'\n\r';
	local QRY;

	local CONFIG_HIDE_GROUP=1;

	case "${GRP}" in
		'' | ::	) QRY='::';CONFIG_HIDE_GROUP=0;;
		*::	) QRY=${GRP};CONFIG_HIDE_GROUP=0;;

		::*:	) QRY=${GRP};;
		::*	) QRY=${GRP}:;;
		*::*:	) QRY=${GRP};;
		*::*	) QRY=${GRP}:;;
		*:	) QRY=${GRP};;

		*	) QRY=${GRP}:;;
	esac

	CONFIG_SHOW_NAMESPACE=${CONFIG_SHOW_NAMESPACE:-0} ConfigSearch "${QRY}"
	return 0;
}

ConfigListWithValue(){ # ((Namespace::)Group)
	CONFIG_SHOW_VALUE=1 ConfigList "${@}"
}

ConfigListAll(){ ConfigSearch; }

ConfigSearchGroup(){ # ((Namespace::):Group)
	local QRY=${1};
	local GRP QRYX X;

	case "${QRY}" in
		''	) QRY='::'; QRYX='';;
		::*	) QRYX='';;
		*:: | *::* ) QRYX=${QRY};;
		*	) QRYX='';;
	esac

	local IFS=$'\n\r';
	for l in `ConfigSearch "${QRY}"`; do
		case "${l}" in
			${QRYX}* )
			GRP=${l#*::};
			GRP=${GRP%:*};

			eval local CSG_${GRP};
			eval X=\${CSG_${GRP}};
			[ "${X}" != '1' ] && echo ${GRP}
			eval local CSG_${GRP}=1;
			;;
		esac
	done
	return 0;
}

ConfigListGroup(){ # (Namespace)
	local NS=${1};

	case "${NS}" in
		'' | ::	) QRY='::';;
		*::	) QRY=${NS};;
		*	) QRY=${NS}::;;

	esac

	ConfigSearchGroup "${QRY}"
	return ${?};
}

ConfigGetType(){
	case "${1}" in
		''	) echo 'blank';;
		::	) echo 'namespace';;
		*::*::*	) echo 'invalid';;
		*::*:*:*) echo 'invalid';;

		::*:	) echo 'group';;
		::*:*	) echo 'group+key';;
		::*	) echo 'key';;

		*::*:	) echo 'namespace+group';;
		*::*:*	) echo 'namespace+group+key';;
		*::	) echo 'namespace';;
		*::*	) echo 'namespace+key';;

		*:*:*	) echo ''invalid'';;
		*:	) echo 'group';;
		*:*	) echo 'group+key';;
		*	) echo 'key';;
	esac
	return 0;
}

ConfigKeyConvdb(){
cat <<"EOF";
 	20
!	21
\$	24
\*	2A
+	2B
,	2C
-	2D
.	2E
\/	2F
:	3A
@	40
EOF
	return 0;
}

ConfigKey2Env(){ # ValNameToReturn, (Key)
	[ "${1}" = '' ] && return 1;
	eval local _KEY_K2E_=\${2:-\${${1}}};
	local _VN_K2E_=${1};

	ConfigGetEnv
	case "${_KEY_K2E_}" in
		::*	) _KEY_K2E_=${NAMESPACE_DIV}${_KEY_K2E_:2};;
		*::*	) _KEY_K2E_=${_KEY_K2E_/::/${NAMESPACE_DIV}};;
		*:*	) _KEY_K2E_=${NAMESPACE_DIV}${_KEY_K2E_};;
		*	) _KEY_K2E_=${_KEY_K2E_/::/${NAMESPACE_DIV}};;
	esac
	_KEY_K2E_=${_KEY_K2E_/:/${GROUP_DIV}};

	case "${_KEY_K2E_}" in
		*:* ) eval ${_VN_K2E_}=''; return 1;;
	esac

	ConfigKeyEncode "${_VN_K2E_}" "DC_${_KEY_K2E_}"
	return 0;
}

ConfigEnv2Key(){ # ValNameToReturn, (Key)
	[ "${1}" = '' ] && return 1;
	eval local _KEY_E2K_=\${2:-\${${1}}};
	local _VN_E2K_=${1};

	ConfigGetEnv
	case "${_KEY_E2K_}" in
		DC_${NAMESPACE_DIV}* )
			_KEY_E2K_=${_KEY_E2K_/DC_${NAMESPACE_DIV}/};
			_KEY_E2K_=${_KEY_E2K_/${GROUP_DIV}/:};
			ConfigKeyDecode "${_VN_E2K_}" "${_KEY_E2K_}"
			return 0;;
		DC_* )
			_KEY_E2K_=${_KEY_E2K_:3};
			_KEY_E2K_=${_KEY_E2K_/${NAMESPACE_DIV}/::};
			_KEY_E2K_=${_KEY_E2K_/${GROUP_DIV}/:};
			ConfigKeyDecode "${_VN_E2K_}" "${_KEY_E2K_}"
			return 0;;
	esac

	return 1;
}

ConfigEnv2KeyStrict(){ # ValNameToReturn, (Key)
	eval local _KEY_E2KS_=\${2:-\${${1}}};
	ConfigGetEnv
	case "${_KEY_E2KS_}" in
		*${NAMESPACE_DIV}*${NAMESPACE_DIV}* | *${GROUP_DIV}*${GROUP_DIV}* ) return 1;;
	esac
	ConfigEnv2Key "${1}" "${2}"
	return 0;
}

ConfigKeyEncode(){ # ValNameToReturn, (Key)
	local x;
	[ "${1}" = '' ] && return 1;
	eval local _KEY_ENC_=\${2:-\${${1}}};
	local _VN_ENC_=${1};

	local IFS=$'\n\r';
	for x in `ConfigKeyConvdb`; do
		eval _KEY_ENC_=\${_KEY_ENC_//${x%	*}/__0x${x#*	}__};
	done

	eval ${_VN_ENC_}=\"${_KEY_ENC_}\";

	return 0;
}

ConfigKeyDecode(){ # ValNameToReturn, (Key)
	local x;
	[ "${1}" = '' ] && return 1;
	eval local _KEY_DEC_=\${2:-\${${1}}};
	local _VN_DEC_=${1};

	local IFS=$'\n\r';
	for x in `ConfigKeyConvdb`; do
		eval _KEY_DEC_=\${_KEY_DEC_//__0x${x#*	}__/${x%	*}};
	done

	eval ${_VN_DEC_}=\"${_KEY_DEC_}\";

	return 0;
}
