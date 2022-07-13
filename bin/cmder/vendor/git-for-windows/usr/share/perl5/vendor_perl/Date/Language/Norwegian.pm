##
## Norwegian tables
##

package Date::Language::Norwegian;

use Date::Language ();
use vars qw(@ISA @DoW @DoWs @MoY @MoYs @AMPM @Dsuf %MoY %DoW $VERSION);
@ISA = qw(Date::Language);
$VERSION = "1.01";

@MoY  = qw(Januar Februar Mars April Mai Juni
	   Juli August September Oktober November Desember);
@MoYs = qw(Jan Feb Mar Apr Mai Jun Jul Aug Sep Okt Nov Des);
@DoW  = qw(Søndag Mandag Tirsdag Onsdag Torsdag Fredag Lørdag Søndag);
@DoWs = qw(Søn Man Tir Ons Tor Fre Lør Søn);

use Date::Language::English ();
@AMPM =   @{Date::Language::English::AMPM};
@Dsuf =   @{Date::Language::English::Dsuf};

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

1;
