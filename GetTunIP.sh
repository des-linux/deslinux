#!/bin/sh

main(){
	local RV=0;
	local NID1="${1}";
	local NID2="${2}";

	NID1=$((NID1+0));
	NID2=$((NID2+0));

	[ "${NID2}" = '' ] && {
		echo "${0} <Network ID 1> <Network ID 2>"
		return 1;
	}

	[ "${NID1}" = "${NID2}" ] && {
		echo "2 network is same."
		return 1;
	}	

	# Always b is larger
	[ "${NID1}" -ge "${NID2}" ] && {
		local x="${NID2}";
		NID2="${NID1}";
		NID1="${x}";
		RV=1;
	}

	[ "${NID2}" -ge "256" ] && {
		echo Illegal IP range
		return 1;
	}

	# Calc SeqID
	local p=0;
	local SID=0;

	while [ "${p}" -lt "${NID1}" ]; do
		CountIPinBlock ${p}
		p=$((p+1));
		SID=$((SID+COUNT_IP+1));
	done

	local RID=$((NID2-NID1));

	local SID1=$(((RID-1)*2));
	local SID2=$((SID1+1));
	SID1=$((SID+SID1));
	SID2=$((SID+SID2));

	local IP3=$((SID1/256));
	IP3=$((IP3+1))
	local IP4=$((SID1%256));
	local IP4b=$((IP4+1));

	[ ! "${RV}" = '1' ] && {
		echo "[${NID1}]: 10.0.${IP3}.${IP4}/31 - [${NID2}]: 10.0.${IP3}.${IP4b}/31"
	} || {
		echo "[${NID2}]: 10.0.${IP3}.${IP4b}/31 - [${NID1}]: 10.0.${IP3}.${IP4}/31"
	}

	return 0;
}

CountIPinBlock(){
	COUNT_IP=0;
	local a="${1}";
	local b=$((255-a));
	COUNT_IP=$(((b*2)-1))
	return 0;
}



main "${@}"

