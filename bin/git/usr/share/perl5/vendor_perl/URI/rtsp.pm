package URI::rtsp;

use strict;
use warnings;

our $VERSION = '5.34';

use parent 'URI::http';

sub default_port { 554 }

1;
