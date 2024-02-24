package URI::_punycode;

use strict;
use warnings;

our $VERSION = '5.21';

use Exporter 'import';
our @EXPORT = qw(encode_punycode decode_punycode);

use integer;

our $DEBUG = 0;

use constant BASE => 36;
use constant TMIN => 1;
use constant TMAX => 26;
use constant SKEW => 38;
use constant DAMP => 700;
use constant INITIAL_BIAS => 72;
use constant INITIAL_N => 128;

my $Delimiter = chr 0x2D;
my $BasicRE   = qr/[\x00-\x7f]/;

sub _croak { require Carp; Carp::croak(@_); }

sub _digit_value {
    my $code = shift;
    return ord($code) - ord("A") if $code =~ /[A-Z]/;
    return ord($code) - ord("a") if $code =~ /[a-z]/;
    return ord($code) - ord("0") + 26 if $code =~ /[0-9]/;
    return;
}

sub _code_point {
    my $digit = shift;
    return $digit + ord('a') if 0 <= $digit && $digit <= 25;
    return $digit + ord('0') - 26 if 26 <= $digit && $digit <= 36;
    die 'NOT COME HERE';
}

sub _adapt {
    my($delta, $numpoints, $firsttime) = @_;
    $delta = $firsttime ? $delta / DAMP : $delta / 2;
    $delta += $delta / $numpoints;
    my $k = 0;
    while ($delta > ((BASE - TMIN) * TMAX) / 2) {
	$delta /= BASE - TMIN;
	$k += BASE;
    }
    return $k + (((BASE - TMIN + 1) * $delta) / ($delta + SKEW));
}

sub decode_punycode {
    my $code = shift;

    my $n      = INITIAL_N;
    my $i      = 0;
    my $bias   = INITIAL_BIAS;
    my @output;

    if ($code =~ s/(.*)$Delimiter//o) {
	push @output, map ord, split //, $1;
	return _croak('non-basic code point') unless $1 =~ /^$BasicRE*$/o;
    }

    while ($code) {
	my $oldi = $i;
	my $w    = 1;
    LOOP:
	for (my $k = BASE; 1; $k += BASE) {
	    my $cp = substr($code, 0, 1, '');
	    my $digit = _digit_value($cp);
	    defined $digit or return _croak("invalid punycode input");
	    $i += $digit * $w;
	    my $t = ($k <= $bias) ? TMIN
		: ($k >= $bias + TMAX) ? TMAX : $k - $bias;
	    last LOOP if $digit < $t;
	    $w *= (BASE - $t);
	}
	$bias = _adapt($i - $oldi, @output + 1, $oldi == 0);
	warn "bias becomes $bias" if $DEBUG;
	$n += $i / (@output + 1);
	$i = $i % (@output + 1);
	splice(@output, $i, 0, $n);
	warn join " ", map sprintf('%04x', $_), @output if $DEBUG;
	$i++;
    }
    return join '', map chr, @output;
}

sub encode_punycode {
    my $input = shift;
    my @input = split //, $input;

    my $n     = INITIAL_N;
    my $delta = 0;
    my $bias  = INITIAL_BIAS;

    my @output;
    my @basic = grep /$BasicRE/, @input;
    my $h = my $b = @basic;
    push @output, @basic;
    push @output, $Delimiter if $b && $h < @input;
    warn "basic codepoints: (@output)" if $DEBUG;

    while ($h < @input) {
	my $m = _min(grep { $_ >= $n } map ord, @input);
	warn sprintf "next code point to insert is %04x", $m if $DEBUG;
	$delta += ($m - $n) * ($h + 1);
	$n = $m;
	for my $i (@input) {
	    my $c = ord($i);
	    $delta++ if $c < $n;
	    if ($c == $n) {
		my $q = $delta;
	    LOOP:
		for (my $k = BASE; 1; $k += BASE) {
		    my $t = ($k <= $bias) ? TMIN :
			($k >= $bias + TMAX) ? TMAX : $k - $bias;
		    last LOOP if $q < $t;
		    my $cp = _code_point($t + (($q - $t) % (BASE - $t)));
		    push @output, chr($cp);
		    $q = ($q - $t) / (BASE - $t);
		}
		push @output, chr(_code_point($q));
		$bias = _adapt($delta, $h + 1, $h == $b);
		warn "bias becomes $bias" if $DEBUG;
		$delta = 0;
		$h++;
	    }
	}
	$delta++;
	$n++;
    }
    return join '', @output;
}

sub _min {
    my $min = shift;
    for (@_) { $min = $_ if $_ <= $min }
    return $min;
}

1;
__END__

=encoding utf8

=head1 NAME

URI::_punycode - encodes Unicode string in Punycode

=head1 SYNOPSIS

  use strict;
  use warnings;
  use utf8;

  use URI::_punycode qw(encode_punycode decode_punycode);

  # encode a unicode string
  my $punycode = encode_punycode('http://☃.net'); # http://.net-xc8g
  $punycode = encode_punycode('bücher'); # bcher-kva
  $punycode = encode_punycode('他们为什么不说中文'); # ihqwcrb4cv8a8dqg056pqjye

  # decode a punycode string back into a unicode string
  my $unicode = decode_punycode('http://.net-xc8g'); # http://☃.net
  $unicode = decode_punycode('bcher-kva'); # bücher
  $unicode = decode_punycode('ihqwcrb4cv8a8dqg056pqjye'); # 他们为什么不说中文

=head1 DESCRIPTION

L<URI::_punycode> is a module to encode / decode Unicode strings into
L<Punycode|https://tools.ietf.org/html/rfc3492>, an efficient
encoding of Unicode for use with L<IDNA|https://tools.ietf.org/html/rfc5890>.

=head1 FUNCTIONS

All functions throw exceptions on failure. You can C<catch> them with
L<Syntax::Keyword::Try> or L<Try::Tiny>. The following functions are exported
by default.

=head2 encode_punycode

  my $punycode = encode_punycode('http://☃.net');  # http://.net-xc8g
  $punycode = encode_punycode('bücher'); # bcher-kva
  $punycode = encode_punycode('他们为什么不说中文') # ihqwcrb4cv8a8dqg056pqjye

Takes a Unicode string (UTF8-flagged variable) and returns a Punycode
encoding for it.

=head2 decode_punycode

  my $unicode = decode_punycode('http://.net-xc8g'); # http://☃.net
  $unicode = decode_punycode('bcher-kva'); # bücher
  $unicode = decode_punycode('ihqwcrb4cv8a8dqg056pqjye'); # 他们为什么不说中文

Takes a Punycode encoding and returns original Unicode string.

=head1 AUTHOR

Tatsuhiko Miyagawa <F<miyagawa@bulknews.net>> is the author of
L<IDNA::Punycode> which was the basis for this module.

=head1 SEE ALSO

L<IDNA::Punycode>, L<RFC 3492|https://tools.ietf.org/html/rfc3492>,
L<RFC 5891|https://tools.ietf.org/html/rfc5891>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
