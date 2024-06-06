# To the extent possible under law, the author(s) have dedicated all 
# copyright and related and neighboring rights to this software to the 
# public domain worldwide. This software is distributed without any warranty. 
# You should have received a copy of the CC0 Public Domain Dedication along 
# with this software. 
# If not, see <https://creativecommons.org/publicdomain/zero/1.0/>. 


# System-wide profile file

# Some resources...
# Customizing Your Shell: http://www.dsl.org/cookbook/cookbook_5.html#SEC69
# Consistent BackSpace and Delete Configuration:
#   http://www.ibb.net/~anne/keyboard.html
# The Linux Documentation Project: https://www.tldp.org/
# The Linux Cookbook: https://www.tldp.org/LDP/linuxcookbook/html/
# Greg's Wiki https://mywiki.wooledge.org/

# Setup some default paths. Note that this order will allow user installed
# software to override 'system' software.
# Modifying these default path settings can be done in different ways.
# To learn more about startup files, refer to your shell's man page.

MSYS2_PATH="/usr/local/bin:/usr/bin:/bin"
MANPATH='/usr/local/man:/usr/share/man:/usr/man:/share/man'
INFOPATH='/usr/local/info:/usr/share/info:/usr/info:/share/info'

case "${MSYS2_PATH_TYPE:-inherit}" in
  strict)
    # Do not inherit any path configuration, and allow for full customization
    # of external path. This is supposed to be used in special cases such as
    # debugging without need to change this file, but not daily usage.
    unset ORIGINAL_PATH
    ;;
  inherit)
    # Inherit previous path. Note that this will make all of the Windows path
    # available in current shell, with possible interference in project builds.
    ORIGINAL_PATH="${ORIGINAL_PATH:-${PATH}}"
    ;;
  *)
    # Do not inherit any path configuration but configure a default Windows path
    # suitable for normal usage with minimal external interference.
    WIN_ROOT="$(PATH=${MSYS2_PATH} exec cygpath -Wu)"
    ORIGINAL_PATH="${WIN_ROOT}/System32:${WIN_ROOT}:${WIN_ROOT}/System32/Wbem:${WIN_ROOT}/System32/WindowsPowerShell/v1.0/"
esac

unset MINGW_MOUNT_POINT
. '/etc/msystem'
case "${MSYSTEM}" in
MINGW*|CLANG*|UCRT*)
  MINGW_MOUNT_POINT="${MINGW_PREFIX}"
  PATH="${MINGW_MOUNT_POINT}/bin:${MSYS2_PATH}${ORIGINAL_PATH:+:${ORIGINAL_PATH}}"
  PKG_CONFIG_PATH="${MINGW_MOUNT_POINT}/lib/pkgconfig:${MINGW_MOUNT_POINT}/share/pkgconfig"
  PKG_CONFIG_SYSTEM_INCLUDE_PATH="${MINGW_MOUNT_POINT}/include"
  PKG_CONFIG_SYSTEM_LIBRARY_PATH="${MINGW_MOUNT_POINT}/lib"
  ACLOCAL_PATH="${MINGW_MOUNT_POINT}/share/aclocal:/usr/share/aclocal"
  MANPATH="${MINGW_MOUNT_POINT}/local/man:${MINGW_MOUNT_POINT}/share/man:${MANPATH}"
  INFOPATH="${MINGW_MOUNT_POINT}/local/info:${MINGW_MOUNT_POINT}/share/info:${INFOPATH}"
  ;;
*)
  PATH="${MSYS2_PATH}:/opt/bin${ORIGINAL_PATH:+:${ORIGINAL_PATH}}"
  PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/share/pkgconfig:/lib/pkgconfig"
esac

CONFIG_SITE="/etc/config.site"

MAYBE_FIRST_START=false
if [ ! -d "${HOME}" ]; then
  printf "\e[1;32mMSYS2 is starting for the first time. Executing the initial setup.\e[1;0m\n" 1>&2;
  MAYBE_FIRST_START=true
fi

SYSCONFDIR="${SYSCONFDIR:=/etc}"

# TMP and TEMP as defined in the Windows environment must be kept
# for windows apps, even if started from msys2. However, leaving
# them set to the default Windows temporary directory or unset
# can have unexpected consequences for msys2 apps, so we define 
# our own to match GNU/Linux behaviour.
ORIGINAL_TMP="${ORIGINAL_TMP:-${TMP}}"
ORIGINAL_TEMP="${ORIGINAL_TEMP:-${TEMP}}"
#TMP="/tmp"
#TEMP="/tmp"
case "$TMP" in *\\*) TMP="$(cygpath -m "$TMP")";; esac
case "$TEMP" in *\\*) TEMP="$(cygpath -m "$TEMP")";; esac
test -d "$TMPDIR" || test ! -d "$TMP" || {
  TMPDIR="$TMP"
  export TMPDIR
}


# Shell dependent settings
profile_d ()
{
  local file=
  for file in $(export LC_COLLATE=C; echo /etc/profile.d/*.$1); do
    [ -e "${file}" ] && . "${file}"
  done
  
  if [ -n "${MINGW_MOUNT_POINT}" ]; then
    for file in $(export LC_COLLATE=C; echo ${MINGW_MOUNT_POINT}/etc/profile.d/*.$1); do
      [ -e "${file}" ] && . "${file}"
    done
  fi
}

for postinst in $(export LC_COLLATE=C; echo /etc/post-install/*.post); do
  [ -e "${postinst}" ] && . "${postinst}"
done

if [ ! "x${BASH_VERSION}" = "x" ]; then
  HOSTNAME="$(exec /usr/bin/hostname)"
  SHELL=`which bash`
  profile_d sh
  [ -f "/etc/bash.bashrc" ] && . "/etc/bash.bashrc"
elif [ ! "x${KSH_VERSION}" = "x" ]; then
  typeset -l HOSTNAME="$(exec /usr/bin/hostname)"
  profile_d sh
  PS1=$(print '\033]0;${PWD}\n\033[32m${USER}@${HOSTNAME} \033[33m${PWD/${HOME}/~}\033[0m\n$ ')
elif [ ! "x${ZSH_VERSION}" = "x" ]; then
  HOSTNAME="$(exec /usr/bin/hostname)"
  profile_d sh
  profile_d zsh
  PS1='(%n@%m)[%h] %~ %% '
  SHELL=`which zsh`
elif [ ! "x${POSH_VERSION}" = "x" ]; then
  HOSTNAME="$(exec /usr/bin/hostname)"
  PS1="$ "
else 
  HOSTNAME="$(exec /usr/bin/hostname)"
  profile_d sh
  PS1="$ "
fi

if [ -n "$ACLOCAL_PATH" ]
then
  export ACLOCAL_PATH
fi

export PATH MANPATH INFOPATH PKG_CONFIG_PATH PKG_CONFIG_SYSTEM_INCLUDE_PATH PKG_CONFIG_SYSTEM_LIBRARY_PATH USER TMP TEMP HOSTNAME PS1 SHELL ORIGINAL_TMP ORIGINAL_TEMP ORIGINAL_PATH CONFIG_SITE
unset PATH_SEPARATOR

if [ "$MAYBE_FIRST_START" = "true" ]; then
  printf "\e[1;32mInitial setup complete. MSYS2 is now ready to use.\e[1;0m\n" 1>&2;
fi
unset MAYBE_FIRST_START
