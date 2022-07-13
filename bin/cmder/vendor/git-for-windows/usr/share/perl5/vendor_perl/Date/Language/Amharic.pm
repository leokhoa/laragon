##
## Amharic tables
##

package Date::Language::Amharic;

use Date::Language ();
use vars qw(@ISA @DoW @DoWs @MoY @MoYs @AMPM @Dsuf %MoY %DoW $VERSION);
@ISA = qw(Date::Language);
$VERSION = "1.00";

if ( $] >= 5.006 ) {
@DoW = (
"\x{12a5}\x{1211}\x{12f5}",
"\x{1230}\x{129e}",
"\x{121b}\x{12ad}\x{1230}\x{129e}",
"\x{1228}\x{1261}\x{12d5}",
"\x{1210}\x{1219}\x{1235}",
"\x{12d3}\x{122d}\x{1265}",
"\x{1245}\x{12f3}\x{121c}"
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
@AMPM = ( "\x{1320}\x{12cb}\x{1275}", "\x{12a8}\x{1230}\x{12d3}\x{1275}" );

@Dsuf = ("\x{129b}" x 31);
}
else {
@DoW = (
"እሑድ",
"ሰኞ",
"ማክሰኞ",
"ረቡዕ",
"ሐሙስ",
"ዓርብ",
"ቅዳሜ"
);
@MoY = (
"ጃንዩወሪ",
"ፌብሩወሪ",
"ማርች",
"ኤፕረል",
"ሜይ",
"ጁን",
"ጁላይ",
"ኦገስት",
"ሴፕቴምበር",
"ኦክተውበር",
"ኖቬምበር",
"ዲሴምበር"
);
@DoWs = map { substr($_,0,9) } @DoW;
@MoYs = map { substr($_,0,9) } @MoY;
@AMPM = ( "ጠዋት", "ከሰዓት" );

@Dsuf = ("ኛ" x 31);
}

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
