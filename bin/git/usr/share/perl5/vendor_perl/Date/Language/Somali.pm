##
## Somali tables
##

package Date::Language::Somali;

use Date::Language ();
use vars qw(@ISA @DoW @DoWs @MoY @MoYs @AMPM @Dsuf %MoY %DoW $VERSION);
@ISA = qw(Date::Language);
$VERSION = "0.99";

@DoW = qw(Axad Isniin Salaaso Arbaco Khamiis Jimco Sabti);
@MoY = (
"Bisha Koobaad",
"Bisha Labaad",
"Bisha Saddexaad",
"Bisha Afraad",
"Bisha Shanaad",
"Bisha Lixaad",
"Bisha Todobaad",
"Bisha Sideedaad",
"Bisha Sagaalaad",
"Bisha Tobnaad",
"Bisha Kow iyo Tobnaad",
"Bisha Laba iyo Tobnaad"
);
@DoWs = map { substr($_,0,3) } @DoW;
@MoYs = (
"Kob",
"Lab",
"Sad",
"Afr",
"Sha",
"Lix",
"Tod",
"Sid",
"Sag",
"Tob",
"KIT",
"LIT"
);
@AMPM = qw(SN GN);

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
