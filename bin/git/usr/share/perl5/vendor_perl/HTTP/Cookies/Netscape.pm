package HTTP::Cookies::Netscape;

use strict;

our $VERSION = '6.11';

require HTTP::Cookies;
our @ISA=qw(HTTP::Cookies);

sub load
{
    my ($self, $file) = @_;
    $file ||= $self->{'file'} || return;

    local $/ = "\n";  # make sure we got standard record separator
    open (my $fh, '<', $file) || return;
    my $magic = <$fh>;
    chomp $magic;
    unless ($magic =~ /^#(?: Netscape)? HTTP Cookie File/) {
        warn "$file does not look like a netscape cookies file";
        return;
    }

    my $now = time() - $HTTP::Cookies::EPOCH_OFFSET;
    while (my $line = <$fh>) {
        chomp($line);
        $line =~ s/\s*\#HttpOnly_//;
        next if $line =~ /^\s*\#/;
        next if $line =~ /^\s*$/;
        $line =~ tr/\n\r//d;
        my($domain,$bool1,$path,$secure, $expires,$key,$val) = split(/\t/, $line);
        $secure = ($secure eq "TRUE");
        $self->set_cookie(undef, $key, $val, $path, $domain, undef, 0, $secure, $expires-$now, 0);
    }
    1;
}

sub save
{
    my $self = shift;
    my %args = (
        file => $self->{'file'},
        ignore_discard => $self->{'ignore_discard'},
        @_ == 1 ? ( file => $_[0] ) : @_
    );
    Carp::croak('Unexpected argument to save method') if keys %args > 2;
    my $file = $args{'file'} || return;

    open(my $fh, '>', $file) || return;

    # Use old, now broken link to the old cookie spec just in case something
    # else (not us!) requires the comment block exactly this way.
    print {$fh} <<EOT;
# Netscape HTTP Cookie File
# http://www.netscape.com/newsref/std/cookie_spec.html
# This is a generated file!  Do not edit.

EOT

    my $now = time - $HTTP::Cookies::EPOCH_OFFSET;
    $self->scan(sub {
        my ($version, $key, $val, $path, $domain, $port, $path_spec, $secure, $expires, $discard, $rest) = @_;
        return if $discard && !$args{'ignore_discard'};
        $expires = $expires ? $expires - $HTTP::Cookies::EPOCH_OFFSET : 0;
        return if $now > $expires;
        $secure = $secure ? "TRUE" : "FALSE";
        my $bool = $domain =~ /^\./ ? "TRUE" : "FALSE";
        print {$fh} join("\t", $domain, $bool, $path, $secure, $expires, $key, $val), "\n";
    });
    1;
}

1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Cookies::Netscape - Access to Netscape cookies files

=head1 VERSION

version 6.11

=head1 SYNOPSIS

 use LWP;
 use HTTP::Cookies::Netscape;
 $cookie_jar = HTTP::Cookies::Netscape->new(
   file => "c:/program files/netscape/users/ZombieCharity/cookies.txt",
 );
 my $browser = LWP::UserAgent->new;
 $browser->cookie_jar( $cookie_jar );

=head1 DESCRIPTION

This is a subclass of C<HTTP::Cookies> that reads (and optionally
writes) Netscape/Mozilla cookie files.

See the documentation for L<HTTP::Cookies>.

=head1 CAVEATS

Please note that the Netscape/Mozilla cookie file format can't store
all the information available in the Set-Cookie2 headers, so you will
probably lose some information if you save in this format.

At time of writing, this module seems to work fine with Mozilla
Phoenix/Firebird.

=head1 SEE ALSO

L<HTTP::Cookies::Microsoft>

=head1 AUTHOR

Gisle Aas <gisle@activestate.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2002 by Gisle Aas.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#ABSTRACT: Access to Netscape cookies files

