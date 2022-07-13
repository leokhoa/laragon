##
## Gedeo tables
##

package Date::Language::Gedeo;

use Date::Language ();
use vars qw(@ISA @DoW @DoWs @MoY @MoYs @AMPM @Dsuf %MoY %DoW $VERSION);
@ISA = qw(Date::Language);
$VERSION = "0.99";

@DoW = qw( Sanbbattaa Sanno Masano Roobe Hamusse Arbe Qiddamme);
@MoY = (
"Oritto",
"Birre'a",
"Onkkollessa",
"Saddasa",
"Arrasa",
"Qammo",
"Ella",
"Waacibajje",
"Canissa",
"Addolessa",
"Bittitotessa",
"Hegeya"
);
@DoWs = map { substr($_,0,3) } @DoW;
$DoWs[0] = "Snb";
$DoWs[1] = "Sno";
@MoYs = map { substr($_,0,3) } @MoY;
@AMPM = qw(gorsa warreti-udumma);

@Dsuf = (qw(th st nd rd th th th th th th)) x 3;
@Dsuf[11,12,13] = qw(th th th);
@Dsuf[30,31] = qw(th st);

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
