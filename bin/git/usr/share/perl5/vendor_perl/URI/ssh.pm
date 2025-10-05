package URI::ssh;

use strict;
use warnings;

our $VERSION = '5.29';

use parent 'URI::_login';

# ssh://[USER@]HOST[:PORT]/SRC

sub default_port { 22 }

sub secure { 1 }

1;
