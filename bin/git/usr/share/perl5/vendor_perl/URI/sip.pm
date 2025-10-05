#
# Written by Ryan Kereliuk <ryker@ryker.org>.  This file may be
# distributed under the same terms as Perl itself.
#
# The RFC 3261 sip URI is <scheme>:<authority>;<params>?<query>.
#

package URI::sip;

use strict;
use warnings;

use parent qw(URI::_server URI::_userpass);

use URI::Escape ();

our $VERSION = '5.29';

sub default_port { 5060 }

sub authority
{
    my $self = shift;
    $$self =~ m,^($URI::scheme_re:)?([^;?]*)(.*)$,os or die;
    my $start = $1;
    my $authoritystr = $2;
    my $rest = $3;

    if (@_) {
        $authoritystr = shift;
        $authoritystr =~ s/([^$URI::uric])/ URI::Escape::escape_char($1)/ego;
        $$self = $start . $authoritystr . $rest;
    }
    return $authoritystr;
}

sub params_form
{
    my $self = shift;
    $$self =~ m,^((?:$URI::scheme_re:)?)(?:([^;?]*))?(;[^?]*)?(.*)$,os or die;
    my $start = $1 . $2;
    my $paramstr = $3;
    my $rest = $4;

    if (@_) {
	my @paramarr;
	for (my $i = 0; $i < @_; $i += 2) {
	    push(@paramarr, "$_[$i]=$_[$i+1]");
	}
	$paramstr = join(";", @paramarr);
	$$self = $start . ";" . $paramstr . $rest;
    }
    $paramstr =~ s/^;//o;
    return split(/[;=]/, $paramstr);
}

sub params
{
    my $self = shift;
    $$self =~ m,^((?:$URI::scheme_re:)?)(?:([^;?]*))?(;[^?]*)?(.*)$,os or die;
    my $start = $1 . $2;
    my $paramstr = $3;
    my $rest = $4;

    if (@_) {
        $paramstr = shift; 
        $$self = $start . ";" . $paramstr . $rest;
    }
    $paramstr =~ s/^;//o;
    return $paramstr;
}

# Inherited methods that make no sense for a SIP URI.
sub path {}
sub path_query {}
sub path_segments {}
sub abs { shift }
sub rel { shift }
sub query_keywords {}

1;
