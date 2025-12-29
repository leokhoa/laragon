package URI::_query;

use strict;
use warnings;

use URI ();
use URI::Escape qw(uri_unescape);
use Scalar::Util ();

our $VERSION = '5.34';

sub query
{
    my $self = shift;
    $$self =~ m,^([^?\#]*)(?:\?([^\#]*))?(.*)$,s or die;

    if (@_) {
	my $q = shift;
	$$self = $1;
	if (defined $q) {
	    $q =~ s/([^$URI::uric])/ URI::Escape::escape_char($1)/ego;
	    utf8::downgrade($q);
	    $$self .= "?$q";
	}
	$$self .= $3;
    }
    $2;
}

# Handle ...?foo=bar&bar=foo type of query
sub query_form {
    my $self = shift;
    my $old = $self->query;
    if (@_) {
        # Try to set query string
        my $delim;
        my $r = $_[0];
        if (_is_array($r)) {
            $delim = $_[1];
            @_ = @$r;
        }
        elsif (ref($r) eq "HASH") {
            $delim = $_[1];
            @_ = map { $_ => $r->{$_} } sort keys %$r;
        }
        $delim = pop if @_ % 2;

        my @query;
        while (my($key,$vals) = splice(@_, 0, 2)) {
            $key = '' unless defined $key;
	    $key =~ s/([;\/?:@&=+,\$\[\]%])/ URI::Escape::escape_char($1)/eg;
	    $key =~ s/ /+/g;
	    $vals = [_is_array($vals) ? @$vals : $vals];
            for my $val (@$vals) {
                if (defined $val) {
                    $val =~ s/([;\/?:@&=+,\$\[\]%])/ URI::Escape::escape_char($1)/eg;
                    $val =~ s/ /+/g;
                    push(@query, "$key=$val");
                }
                else {
                    push(@query, $key);
                }
            }
        }
        if (@query) {
            unless ($delim) {
                $delim = $1 if $old && $old =~ /([&;])/;
                $delim ||= $URI::DEFAULT_QUERY_FORM_DELIMITER || "&";
            }
            $self->query(join($delim, @query));
        }
        else {
            $self->query(undef);
        }
    }
    return if !defined($old) || !length($old) || !defined(wantarray);
    return unless $old =~ /=/; # not a form
    map { ( defined ) ? do { s/\+/ /g; uri_unescape($_) } : undef }
         map { /=/ ? split(/=/, $_, 2) : ($_ => undef)} split(/[&;]/, $old);
}

# Handle ...?dog+bones type of query
sub query_keywords
{
    my $self = shift;
    my $old = $self->query;
    if (@_) {
        # Try to set query string
	my @copy = @_;
	@copy = @{$copy[0]} if @copy == 1 && _is_array($copy[0]);
	for (@copy) { s/([;\/?:@&=+,\$\[\]%])/ URI::Escape::escape_char($1)/eg; }
	$self->query(@copy ? join('+', @copy) : undef);
    }
    return if !defined($old) || !defined(wantarray);
    return if $old =~ /=/;  # not keywords, but a form
    map { uri_unescape($_) } split(/\+/, $old, -1);
}

# Some URI::URL compatibility stuff
sub equery { goto &query }

sub query_param {
    my $self = shift;
    my @old = $self->query_form;

    if (@_ == 0) {
        # get keys
        my (%seen, $i);
        return grep !($i++ % 2 || $seen{$_}++), @old;
    }

    my $key = shift;
    my @i = grep $_ % 2 == 0 && $old[$_] eq $key, 0 .. $#old;

    if (@_) {
        my @new = @old;
        my @new_i = @i;
        my @vals = map { _is_array($_) ? @$_ : $_ } @_;

        while (@new_i > @vals) {
            splice @new, pop @new_i, 2;
        }
        if (@vals > @new_i) {
            my $i = @new_i ? $new_i[-1] + 2 : @new;
            my @splice = splice @vals, @new_i, @vals - @new_i;

            splice @new, $i, 0, map { $key => $_ } @splice;
        }
        if (@vals) {
            #print "SET $new_i[0]\n";
            @new[ map $_ + 1, @new_i ] = @vals;
        }

        $self->query_form(\@new);
    }

    return wantarray ? @old[map $_+1, @i] : @i ? $old[$i[0]+1] : undef;
}

sub query_param_append {
    my $self = shift;
    my $key = shift;
    my @vals = map { _is_array($_) ? @$_ : $_ } @_;
    $self->query_form($self->query_form, $key => \@vals);  # XXX
    return;
}

sub query_param_delete {
    my $self = shift;
    my $key = shift;
    my @old = $self->query_form;
    my @vals;

    for (my $i = @old - 2; $i >= 0; $i -= 2) {
        next if $old[$i] ne $key;
        push(@vals, (splice(@old, $i, 2))[1]);
    }
    $self->query_form(\@old) if @vals;
    return wantarray ? reverse @vals : $vals[-1];
}

sub query_form_hash {
    my $self = shift;
    my @old = $self->query_form;
    if (@_) {
        $self->query_form(@_ == 1 ? %{shift(@_)} : @_);
    }
    my %hash;
    while (my($k, $v) = splice(@old, 0, 2)) {
        if (exists $hash{$k}) {
            for ($hash{$k}) {
                $_ = [$_] unless _is_array($_);
                push(@$_, $v);
            }
        }
        else {
            $hash{$k} = $v;
        }
    }
    return \%hash;
}

sub _is_array {
    return(
        defined($_[0]) &&
        ( Scalar::Util::reftype($_[0]) || '' ) eq "ARRAY" && 
        !(
            Scalar::Util::blessed( $_[0] ) && 
            overload::Method( $_[0], '""' )
        )
    );
}

1;
