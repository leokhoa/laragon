# Add bin path in the home directory ontop of the PATH variable
export PATH="$HOME/bin:$PATH"

# Allow SSH to ask via GUI if the terminal is not usable
test -n "$SSH_ASKPASS" || {
	case "$MSYSTEM" in
	MINGW64)
		export DISPLAY=needs-to-be-defined
		if [ -f /mingw64/bin/git-askpass.exe ]; then
			export SSH_ASKPASS=/mingw64/bin/git-askpass.exe
		else
			export SSH_ASKPASS=/mingw64/libexec/git-core/git-gui--askpass
		fi
		;;
	MINGW32)
		export DISPLAY=needs-to-be-defined
		if [ -f /mingw32/bin/git-askpass.exe ]; then
			export SSH_ASKPASS=/mingw32/bin/git-askpass.exe
		else
			export SSH_ASKPASS=/mingw32/libexec/git-core/git-gui--askpass
		fi
		;;
	CLANGARM64)
		export DISPLAY=needs-to-be-defined
		if [ -f /clangarm64/bin/git-askpass.exe ]; then
			export SSH_ASKPASS=/clangarm64/bin/git-askpass.exe
		else
			export SSH_ASKPASS=/clangarm64/libexec/git-core/git-gui--askpass
		fi
		;;
	esac
}
