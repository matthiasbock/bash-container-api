
export PATH=/usr/lib/ccache:/usr/lib/ccache/bin:$PATH

export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_HARDLINK=1
export CCACHE_MAXFILES=0
export CCACHE_MAXSIZE=0

export CC="ccache gcc"
export CXX="ccache g++"

for compiler in {{,arm-none-eabi-,arm-linux-gnueabi-}gcc,g++}; do
	alias "$compiler"="ccache $compiler"
done

# TODO: Add ccache symlinks for all sorts of available compilers
