package URI::https;

use strict;
use warnings;

our $VERSION = '5.29';

use parent 'URI::http';

sub default_port { 443 }

sub secure { 1 }

1;
