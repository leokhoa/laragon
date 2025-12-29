package URI::rsync;  # http://rsync.samba.org/

# rsync://[USER@]HOST[:PORT]/SRC

use strict;
use warnings;

our $VERSION = '5.34';

use parent qw(URI::_server URI::_userpass);

sub default_port { 873 }

1;
