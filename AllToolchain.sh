#!/bin/sh
for x in /l/src/toolchain/builder-x86/*/bin; do
	export PATH=$x:$PATH;
done
