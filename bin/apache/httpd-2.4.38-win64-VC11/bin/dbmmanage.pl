#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#for more functionality see the HTTPD::UserAdmin module:
# http://www.perl.com/CPAN/modules/by-module/HTTPD/HTTPD-Tools-x.xx.tar.gz
#
# usage: dbmmanage <DBMfile> <command> <user> <password> <groups> <comment>

package dbmmanage;
#                               -ldb    -lndbm    -lgdbm    -lsdbm
BEGIN { @AnyDBM_File::ISA = qw(SDBM_File) }
use strict;
use Fcntl;
use AnyDBM_File ();

sub usage {
    my $cmds = join "|", sort keys %dbmc::;
    die <<SYNTAX;
Usage: dbmmanage [enc] dbname command [username [pw [group[,group] [comment]]]]

    where enc is  -d for crypt encryption (default except on Win32, Netware)
                  -m for MD5 encryption (default on Win32, Netware)
                  -s for SHA1 encryption
                  -p for plaintext

    command is one of: $cmds

    pw of . for update command retains the old password
    pw of - (or blank) for update command prompts for the password

    groups or comment of . (or blank) for update command retains old values
    groups or comment of - for update command clears the existing value
    groups or comment of - for add and adduser commands is the empty value
SYNTAX
}

sub need_sha1_crypt {
    if (!eval ('require "Digest/SHA1.pm";')) {
        print STDERR <<SHAERR;
dbmmanage SHA1 passwords require the interface or the module Digest::SHA1
available from CPAN:

    http://www.cpan.org/modules/by-module/Digest/Digest-MD5-2.12.tar.gz

Please install Digest::SHA1 and try again, or use a different crypt option:

SHAERR
        usage();
    }
}

sub need_md5_crypt {
    if (!eval ('require "Crypt/PasswdMD5.pm";')) {
        print STDERR <<MD5ERR;
dbmmanage MD5 passwords require the module Crypt::PasswdMD5 available from CPAN

    http://www.cpan.org/modules/by-module/Crypt/Crypt-PasswdMD5-1.1.tar.gz

Please install Crypt::PasswdMD5 and try again, or use a different crypt option:

MD5ERR
        usage();
    }
}

# if your osname is in $newstyle_salt, then use new style salt (starts with '_' and contains
# four bytes of iteration count and four bytes of salt).  Otherwise, just use
# the traditional two-byte salt.
# see the man page on your system to decide if you have a newer crypt() lib.
# I believe that 4.4BSD derived systems do (at least BSD/OS 2.0 does).
# The new style crypt() allows up to 20 characters of the password to be
# significant rather than only 8.
#
my $newstyle_salt_platforms = join '|', qw{bsdos}; #others?
my $newstyle_salt = $^O =~ /(?:$newstyle_salt_platforms)/;

# Some platforms just can't crypt() for Apache
#
my $crypt_not_supported_platforms = join '|', qw{MSWin32 NetWare}; #others?
my $crypt_not_supported = $^O =~ /(?:$crypt_not_supported_platforms)/;

my $crypt_method = "crypt";

if ($crypt_not_supported) {
    $crypt_method = "md5";
}

# Some platforms won't jump through our favorite hoops
#
my $not_unix_platforms = join '|', qw{MSWin32 NetWare}; #others?
my $not_unix = $^O =~ /(?:$not_unix_platforms)/;

if ($crypt_not_supported) {
    $crypt_method = "md5";
}

if (@ARGV[0] eq "-d") {
    shift @ARGV;
    if ($crypt_not_supported) {
        print STDERR
              "Warning: Apache/$^O does not support crypt()ed passwords!\n\n";
    }
    $crypt_method = "crypt";
}

if (@ARGV[0] eq "-m") {
    shift @ARGV;
    $crypt_method = "md5";
}

if (@ARGV[0] eq "-p") {
    shift @ARGV;
    if (!$crypt_not_supported) {
        print STDERR
              "Warning: Apache/$^O does not support plaintext passwords!\n\n";
    }
    $crypt_method = "plain";
}

if (@ARGV[0] eq "-s") {
    shift @ARGV;
    need_sha1_crypt();
    $crypt_method = "sha1";
}

if ($crypt_method eq "md5") {
    need_md5_crypt();
}

my($file,$command,$key,$crypted_pwd,$groups,$comment) = @ARGV;

usage() unless $file and $command and defined &{$dbmc::{$command}};

# remove extension if any
my $chop = join '|', qw{db.? pag dir};
$file =~ s/\.($chop)$//;

my $is_update = $command eq "update";
my %DB = ();
my @range = ();
my($mode, $flags) = $command =~
    /^(?:view|check)$/ ? (0644, O_RDONLY) : (0644, O_RDWR|O_CREAT);

tie (%DB, "AnyDBM_File", $file, $flags, $mode) || die "Can't tie $file: $!";
dbmc->$command();
untie %DB;


my $x;
sub genseed {
    my $psf;
    if ($not_unix) {
        srand (time ^ $$ or time ^ ($$ + ($$ << 15)));
    }
    else {
        for (qw(-xlwwa -le)) {
            `ps $_ 2>/dev/null`;
            $psf = $_, last unless $?;
        }
        srand (time ^ $$ ^ unpack("%L*", `ps $psf | gzip -f`));
    }
    @range = (qw(. /), '0'..'9','a'..'z','A'..'Z');
    $x = int scalar @range;
}

sub randchar {
    join '', map $range[rand $x], 1..shift||1;
}

sub saltpw_crypt {
    genseed() unless @range;
    return $newstyle_salt ?
        join '', "_", randchar, "a..", randchar(4) :
        randchar(2);
}

sub cryptpw_crypt {
    my ($pw, $salt) = @_;
    $salt = saltpw_crypt unless $salt;
    crypt $pw, $salt;
}

sub saltpw_md5 {
    genseed() unless @range;
    randchar(8);
}

sub cryptpw_md5 {
    my($pw, $salt) = @_;
    $salt = saltpw_md5 unless $salt;
    Crypt::PasswdMD5::apache_md5_crypt($pw, $salt);
}

sub cryptpw_sha1 {
    my($pw, $salt) = @_;
    '{SHA}' . Digest::SHA1::sha1_base64($pw) . "=";
}

sub cryptpw {
    if ($crypt_method eq "md5") {
        return cryptpw_md5(@_);
    } elsif ($crypt_method eq "sha1") {
        return cryptpw_sha1(@_);
    } elsif ($crypt_method eq "crypt") {
        return cryptpw_crypt(@_);
    }
    @_[0]; # otherwise return plaintext
}

sub getpass {
    my $prompt = shift || "Enter password:";

    unless($not_unix) {
        open STDIN, "/dev/tty" or warn "couldn't open /dev/tty $!\n";
        system "stty -echo;";
    }

    my($c,$pwd);
    print STDERR $prompt;
    while (($c = getc(STDIN)) ne '' and $c ne "\n" and $c ne "\r") {
        $pwd .= $c;
    }

    system "stty echo" unless $not_unix;
    print STDERR "\n";
    die "Can't use empty password!\n" unless length $pwd;
    return $pwd;
}

sub dbmc::update {
    die "Sorry, user `$key' doesn't exist!\n" unless $DB{$key};
    $crypted_pwd = (split /:/, $DB{$key}, 3)[0] if $crypted_pwd eq '.';
    $groups = (split /:/, $DB{$key}, 3)[1] if !$groups || $groups eq '.';
    $comment = (split /:/, $DB{$key}, 3)[2] if !$comment || $comment eq '.';
    if (!$crypted_pwd || $crypted_pwd eq '-') {
        dbmc->adduser;
    }
    else {
        dbmc->add;
    }
}

sub dbmc::add {
    die "Can't use empty password!\n" unless $crypted_pwd;
    unless($is_update) {
        die "Sorry, user `$key' already exists!\n" if $DB{$key};
    }
    $groups = '' if $groups eq '-';
    $comment = '' if $comment eq '-';
    $groups .= ":" . $comment if $comment;
    $crypted_pwd .= ":" . $groups if $groups;
    $DB{$key} = $crypted_pwd;
    my $action = $is_update ? "updated" : "added";
    print "User $key $action with password encrypted to $DB{$key} using $crypt_method\n";
}

sub dbmc::adduser {
    my $value = getpass "New password:";
    die "They don't match, sorry.\n" unless getpass("Re-type new password:") eq $value;
    $crypted_pwd = cryptpw $value;
    dbmc->add;
}

sub dbmc::delete {
    die "Sorry, user `$key' doesn't exist!\n" unless $DB{$key};
    delete $DB{$key}, print "`$key' deleted\n";
}

sub dbmc::view {
    print $key ? "$key:$DB{$key}\n" : map { "$_:$DB{$_}\n" if $DB{$_} } keys %DB;
}

sub dbmc::check {
    die "Sorry, user `$key' doesn't exist!\n" unless $DB{$key};
    my $chkpass = (split /:/, $DB{$key}, 3)[0];
    my $testpass = getpass();
    if (substr($chkpass, 0, 6) eq '$apr1$') {
        need_md5_crypt;
        $crypt_method = "md5";
    } elsif (substr($chkpass, 0, 5) eq '{SHA}') {
        need_sha1_crypt;
        $crypt_method = "sha1";
    } elsif (length($chkpass) == 13 && $chkpass ne $testpass) {
        $crypt_method = "crypt";
    } else {
        $crypt_method = "plain";
    }
    print $crypt_method . (cryptpw($testpass, $chkpass) eq $chkpass
                           ? " password ok\n" : " password mismatch\n");
}

sub dbmc::import {
    while(defined($_ = <STDIN>) and chomp) {
        ($key,$crypted_pwd,$groups,$comment) = split /:/, $_, 4;
        dbmc->add;
    }
}

