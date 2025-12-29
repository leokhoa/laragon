package LWP::Debug;    # legacy

our $VERSION = '6.81';

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(level trace debug conns);

use Carp ();

my @levels = qw(trace debug conns);
our %current_level = ();

sub import {
    my $pack    = shift;
    my $callpkg = caller(0);
    my @symbols = ();
    my @levels  = ();
    for (@_) {
        if (/^[-+]/) {
            push(@levels, $_);
        }
        else {
            push(@symbols, $_);
        }
    }
    Exporter::export($pack, $callpkg, @symbols);
    level(@levels);
}

sub level {
    for (@_) {
        if ($_ eq '+') {    # all on
                            # switch on all levels
            %current_level = map { $_ => 1 } @levels;
        }
        elsif ($_ eq '-') {    # all off
            %current_level = ();
        }
        elsif (/^([-+])(\w+)$/) {
            $current_level{$2} = $1 eq '+';
        }
        else {
            Carp::croak("Illegal level format $_");
        }
    }
}

sub trace { _log(@_) if $current_level{'trace'}; }
sub debug { _log(@_) if $current_level{'debug'}; }
sub conns { _log(@_) if $current_level{'conns'}; }

sub _log {
    my $msg = shift;
    $msg .= "\n" unless $msg =~ /\n$/;    # ensure trailing "\n"

    my ($package, $filename, $line, $sub) = caller(2);
    print STDERR "$sub: $msg";
}

1;

__END__

=pod

=head1 NAME

LWP::Debug - deprecated

=head1 DESCRIPTION

This module has been deprecated.  Please see L<LWP::ConsoleLogger> for your
debugging needs.

LWP::Debug is used to provide tracing facilities, but these are not used
by LWP any more.  The code in this module is kept around
(undocumented) so that 3rd party code that happens to use the old
interfaces continue to run.

One useful feature that LWP::Debug provided (in an imprecise and
troublesome way) was network traffic monitoring.  The following
section provides some hints about recommended replacements.

=head2 Network traffic monitoring

The best way to monitor the network traffic that LWP generates is to
use an external TCP monitoring program.  The
L<WireShark|http://www.wireshark.org/> program is highly recommended for this.

Another approach it to use a debugging HTTP proxy server and make
LWP direct all its traffic via this one.  Call C<< $ua->proxy >> to
set it up and then just use LWP as before.

For less precise monitoring needs just setting up a few simple
handlers might do.  The following example sets up handlers to dump the
request and response objects that pass through LWP:

  use LWP::UserAgent;
  $ua = LWP::UserAgent->new;
  $ua->default_header('Accept-Encoding' => scalar HTTP::Message::decodable());

  $ua->add_handler("request_send",  sub { shift->dump; return });
  $ua->add_handler("response_done", sub { shift->dump; return });

  $ua->get("http://www.example.com");

=head1 SEE ALSO

L<LWP::ConsoleLogger>, L<LWP::ConsoleLogger::Everywhere>, L<LWP::UserAgent>

=cut
