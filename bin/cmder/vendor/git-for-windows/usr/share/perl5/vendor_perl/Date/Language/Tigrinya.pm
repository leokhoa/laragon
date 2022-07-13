##
## Tigrinya tables
##

package Date::Language::Tigrinya;

use Date::Language ();
use vars qw(@ISA @DoW @DoWs @MoY @MoYs @AMPM @Dsuf %MoY %DoW $VERSION);
@ISA = qw(Date::Language);
$VERSION = "1.00";

@DoW = (
"\x{1230}\x{1295}\x{1260}\x{1275}",
"\x{1230}\x{1291}\x{12ed}",
"\x{1230}\x{1209}\x{1235}",
"\x{1228}\x{1261}\x{12d5}",
"\x{1213}\x{1219}\x{1235}",
"\x{12d3}\x{122d}\x{1262}",
"\x{1240}\x{12f3}\x{121d}"
);
@MoY = (
"\x{1303}\x{1295}\x{12e9}\x{12c8}\x{122a}",
"\x{134c}\x{1265}\x{1229}\x{12c8}\x{122a}",
"\x{121b}\x{122d}\x{127d}",
"\x{12a4}\x{1355}\x{1228}\x{120d}",
"\x{121c}\x{12ed}",
"\x{1301}\x{1295}",
"\x{1301}\x{120b}\x{12ed}",
"\x{12a6}\x{1308}\x{1235}\x{1275}",
"\x{1234}\x{1355}\x{1274}\x{121d}\x{1260}\x{122d}",
"\x{12a6}\x{12ad}\x{1270}\x{12cd}\x{1260}\x{122d}",
"\x{1296}\x{126c}\x{121d}\x{1260}\x{122d}",
"\x{12f2}\x{1234}\x{121d}\x{1260}\x{122d}"
);
@DoWs = map { substr($_,0,3) } @DoW;
@MoYs = map { substr($_,0,3) } @MoY;
@AMPM = (
"\x{1295}/\x{1230}",
"\x{12F5}/\x{1230}"
);

@Dsuf = ("\x{12ed}" x 31);

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
