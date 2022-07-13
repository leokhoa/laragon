##
## Swedish tables
## Contributed by Matthew Musgrove <muskrat@mindless.com>
## Corrected by dempa
##

package Date::Language::Swedish;

use Date::Language ();
use vars qw(@ISA @DoW @DoWs @MoY @MoYs @AMPM @Dsuf %MoY %DoW $VERSION);
@ISA = qw(Date::Language);
$VERSION = "1.01";

@MoY  = qw(januari februari mars april maj juni juli augusti september oktober november december);
@MoYs = map { substr($_,0,3) } @MoY;
@DoW  = map($_ . "dagen", qw(sön mån tis ons tors fre lör));
@DoWs = map { substr($_,0,2) } @DoW;

# the ordinals are not typically used in modern times
@Dsuf = ('a' x 2, 'e' x 29);

use Date::Language::English ();
@AMPM =   @{Date::Language::English::AMPM};


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
sub format_o { sprintf("%2de",$_[0]->[3]) }

1;
