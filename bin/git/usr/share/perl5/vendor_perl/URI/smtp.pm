package URI::smtp;   # draft-earhart-url-smtp-00

use strict;
use warnings;

our $VERSION = '5.34';

use parent 'URI::_emailauth';

use URI::Escape qw(uri_unescape);

sub default_port { 25 }

#smtp://<user>;auth=<auth>@<host>:<port>

1;
