#!/bin/sh

prefix=/mingw64
exec_prefix=/mingw64
libdir=${exec_prefix}/lib

LD_PRELOAD=${libdir}/libjemalloc.dll
export LD_PRELOAD
exec "$@"
