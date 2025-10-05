package URI::file::OS2;

use strict;
use warnings;

use parent 'URI::file::Win32';

our $VERSION = '5.29';

# The Win32 version translates k:/foo to file://k:/foo  (?!)
# We add an empty host

sub _file_extract_authority
{
    my $class = shift;
    return $1 if $_[0] =~ s,^\\\\([^\\]+),,;  # UNC
    return $1 if $_[0] =~ s,^//([^/]+),,;     # UNC too?

    if ($_[0] =~ m#^[a-zA-Z]{1,2}:#) {	      # allow for ab: drives
	return "";
    }
    return;
}

sub file {
  my $p = &URI::file::Win32::file;
  return unless defined $p;
  $p =~ s,\\,/,g;
  $p;
}

1;
