package URI::ftps;

use strict;
use warnings;

our $VERSION = '5.34';

use parent 'URI::ftp';

sub default_port { 990 }

sub secure { 1 }

sub encrypt_mode { 'implicit' }

1;
