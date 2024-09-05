
DESLB_SUPPORT_NATIVE_ISOLATION=1

DESLBConfig(){

	"${SHARED_SOURCE_DIR}/configure" \
		--host=${BOOTSTRAP_TARGET} \
		--disable-shared \
		|| return ${?};
	return ${?};
}
