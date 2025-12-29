package URI::QueryParam;
use strict;
use warnings;

our $VERSION = '5.34';

1;

__END__

=head1 NAME

URI::QueryParam - Additional query methods for URIs

=head1 SYNOPSIS

  use URI;

=head1 DESCRIPTION

C<URI::QueryParam> used to provide the
L<< query_form_hash|URI/$hashref = $u->query_form_hash >>,
L<< query_param|URI/@keys = $u->query_param >>
L<< query_param_append|URI/$u->query_param_append($key, $value,...) >>, and
L<< query_param_delete|URI/ @values = $u->query_param_delete($key) >> methods
on L<URI> objects. These methods have been merged into L<URI> itself, so this
module is now a no-op.

=head1 COPYRIGHT

Copyright 2002 Gisle Aas.

=cut
