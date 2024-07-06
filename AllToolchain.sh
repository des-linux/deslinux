#!/bin/sh
for x in /l/old/toolchain/build-i686/*/bin; do
	export PATH=$x:$PATH;
done
