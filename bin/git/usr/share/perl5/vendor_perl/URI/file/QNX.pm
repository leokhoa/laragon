package URI::file::QNX;

use strict;
use warnings;

use parent 'URI::file::Unix';

our $VERSION = '5.29';

sub _file_extract_path
{
    my($class, $path) = @_;
    # tidy path
    $path =~ s,(.)//+,$1/,g; # ^// is correct
    $path =~ s,(/\.)+/,/,g;
    $path = "./$path" if $path =~ m,^[^:/]+:,,; # look like "scheme:"
    $path;
}

1;
