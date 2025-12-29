##
## Austrian tables
##

package Date::Language::Austrian;

use Date::Language ();
use vars qw(@ISA @DoW @DoWs @MoY @MoYs @AMPM @Dsuf %MoY %DoW $VERSION);
@ISA = qw(Date::Language);
$VERSION = "1.01";

@MoY  = qw(Jänner Feber März April Mai Juni
	   Juli August September Oktober November Dezember);
@MoYs = qw(Jän Feb Mär Apr Mai Jun Jul Aug Sep Oct Nov Dez);
@DoW  = qw(Sonntag Montag Dienstag Mittwoch Donnerstag Freitag Samstag);
@DoWs = qw(Son Mon Die Mit Don Fre Sam);

use Date::Language::English ();
@AMPM = @{Date::Language::English::AMPM};
@Dsuf = @{Date::Language::English::Dsuf};

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
