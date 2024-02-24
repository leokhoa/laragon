package URI::_login;

use strict;
use warnings;

use parent qw(URI::_server URI::_userpass);

our $VERSION = '5.21';

# Generic terminal logins.  This is used as a base class for 'telnet',
# 'tn3270', and 'rlogin' URL schemes.

1;
