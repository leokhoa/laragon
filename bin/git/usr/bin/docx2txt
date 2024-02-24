#!/usr/bin/env bash

# docx2txt, a command-line utility to convert Docx documents to text format.
# Copyright (C) 2008 Sandeep Kumar
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

#
# A simple .docx to .txt converter
#
# This script is a wrapper around core docx2txt.pl and saves text output for
# (filename or) filename.docx in filename.txt .
#
# Author : Sandeep Kumar (shimple0 -AT- Yahoo .DOT. COM)
#
# ChangeLog :
#
#    10/08/2008 - Initial version (v0.1)
#    15/08/2008 - Invoking docx2txt.pl with docx document instead of xml file,
#                 so don't need unzip and rm actions now.
#                 Removed dependency on sed for generating output filename.
#    23/09/2008 - Changed #! line to use /usr/bin/env - good suggestion from
#                 Rene Maroufi (info>AT<maroufi>DOT<net) to reduce user work
#                 during installation.
#    15/09/2009 - Added support for directory (holding unzipped content of
#                 .docx file) argument to keep it's usage in sync with main
#                 docx2txt.pl script.
#                 Fixed bug in condition check for input file accessibility.
#    25/11/2009 - Fixed bug in set expression that was resulting in incorrect
#                 handling of file/directory names containing spaces.
#


MYLOC=`dirname "$0"`	# invoked perl script docx2txt.pl is expected here.

function usage ()
{
    cat << _USAGE_

Usage : $0 <file.docx>

	<file.docx> can also specify a directory holding the unzipped
	content of a .docx file.

_USAGE_

    exit 1
}

[ $# != 1 ] && usage

#
# Remove trailing '/'s if any, when input specifies a directory.
#
shopt -s extglob
set "${1%%+(/)}"

if [ -d "$1" ]
then
    if ! [ -r "$1" -a -x "$1" ]
    then
        echo -e "\nCan't access/read input directory <$1>!\n"
        exit 1
    fi
elif ! [ -f "$1" -a -r "$1" -a -s "$1" ]
then
    echo -e "\nCheck if <$1> exists, is readable and has non-zero size!\n"
    exit 1
fi


TEXTFILE=${1/%.docx/.txt}
[ "$1" == "$TEXTFILE" ] && TEXTFILE="$1.txt" 


#
# $1 : filename to check for existence
# $2 : message regarding file
#
function check_for_existence ()
{
    if [ -f "$1" ]
    then
        read -p "overwrite $2 <$1> [y/n] ? " yn
        if [ "$yn" != "y" ]
        then
            echo -e "\nPlease copy <$1> somewhere before running the script.\n"
            echeck=1
        fi
    fi
}

echeck=0
check_for_existence "$TEXTFILE" "Output text file"
[ $echeck -ne 0 ] && exit 1

#
# Invoke perl script to do the actual text extraction
#

"$MYLOC/docx2txt.pl" "$1" "$TEXTFILE"
if [ $? == 0 ]
then
    echo -e "\nText extracted from <$1> is available in <$TEXTFILE>.\n"
else
    echo -e "\nFailed to extract text from <$1>!\n"
fi

