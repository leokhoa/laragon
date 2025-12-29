##
## Hungarian tables based on English
##
#
# This is a just-because-I-stumbled-across-it
# -and-my-wife-is-Hungarian release: if Graham or
# someone adds to docs to Date::Format, I'd be
# glad to correct bugs and extend as neeed.
#

package Date::Language::Hungarian;

=head1 NAME

Date::Language::Hungarian - Magyar format for Date::Format

=head1 SYNOPSIS

	my $lang = Date::Language->new('Hungarian');
	print $lang->time2str("%a %b %e %T %Y", time);

	@lt = localtime(time);
	print $lang->time2str($template, time);
	print $lang->strftime($template, @lt);

	print $lang->time2str($template, time, $zone);
	print $lang->strftime($template, @lt, $zone);

	print $lang->ctime(time);
	print $lang->asctime(@lt);

	print $lang->ctime(time, $zone);
	print $lang->asctime(@lt, $zone);

See L<Date::Format>.

=head1 AUTHOR

Paula Goddard (paula -at- paulacska -dot- com)

=head1 LICENCE

Made available under the same terms as Perl itself.

=cut

use strict;
use warnings;
use base "Date::Language";
use vars qw( @DoW @DoWs @MoY @MoYs @AMPM @Dsuf %MoY %DoW $VERSION);
$VERSION = "1.01";

@DoW = qw(Vasárnap Hétfõ Kedd Szerda Csütörtök Péntek Szombat);
@MoY = qw(Január Február Március Április Május Június
	  Július Augusztus Szeptember Október November December);
@DoWs = map { substr($_,0,3) } @DoW;
@MoYs = map { substr($_,0,3) } @MoY;
@AMPM = qw(DE. DU.);

# There is no 'th or 'nd in Hungarian, just a dot
@Dsuf = (".") x 31;

@MoY{@MoY}  = (0 .. scalar(@MoY));
@MoY{@MoYs} = (0 .. scalar(@MoYs));
@DoW{@DoW}  = (0 .. scalar(@DoW));
@DoW{@DoWs} = (0 .. scalar(@DoWs));

# Formatting routines

sub format_a { $DoWs[$_[0]->[6]] }
sub format_A { $DoW[$_[0]->[6]] }
sub format_b { $MoYs[$_[0]->[4]] }
sub format_B { $MoY[$_[0]->[4]] }
sub format_h { $MoYs[$_[0]->[4]] }
sub format_p { $_[0]->[2] >= 12 ?  $AMPM[1] : $AMPM[0] }
sub format_P { lc($_[0]->[2] >= 12 ?  $AMPM[1] : $AMPM[0]) }
sub format_o { $_[0]->[3].'.' }



sub format_D { &format_y . "." . &format_m . "." . &format_d  }

sub format_y { sprintf("%02d",$_[0]->[5] % 100) }
sub format_d { sprintf("%02d",$_[0]->[3]) }
sub format_m { sprintf("%02d",$_[0]->[4] + 1) }


1;
