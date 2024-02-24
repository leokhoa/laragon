# To the extent possible under law, the author(s) have dedicated all 
# copyright and related and neighboring rights to this software to the 
# public domain worldwide. This software is distributed without any warranty. 
# You should have received a copy of the CC0 Public Domain Dedication along 
# with this software. 
# If not, see <https://creativecommons.org/publicdomain/zero/1.0/>. 

# /etc/profile.d/lang.sh: sourced by /etc/profile.

# The latest version as installed by the MSYS2 Setup program can
# always be found at /etc/defaults/etc/profile.d/lang.sh

# Modifying /etc/profile.d/lang.sh directly will prevent
# setup from updating it.

# System-wide lang.sh file

# if no locale variable is set, indicate terminal charset via LANG
test -z "${LC_ALL:-${LC_CTYPE:-$LANG}}" && export LANG=$(exec /usr/bin/locale -uU)
