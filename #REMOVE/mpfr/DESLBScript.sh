
DESLB_SUPPORT_NATIVE_ISOLATION=1

DESLBConfig(){
	"${SHARED_SOURCE_DIR}/configure" \
		--host=${BOOTSTRAP_TARGET} \
		--disable-shared \
		--with-gmp="${TOOLCHAIN_USR_DIR}" \
		|| return ${?};
	return 0;
}
