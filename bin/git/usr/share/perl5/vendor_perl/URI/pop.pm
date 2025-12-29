package URI::pop;   # RFC 2384

use strict;
use warnings;

our $VERSION = '5.34';

use parent 'URI::_emailauth';

use URI::Escape qw(uri_unescape);

sub default_port { 110 }

#pop://<user>;auth=<auth>@<host>:<port>

1;
