##
## Finnish tables
## Contributed by Matthew Musgrove <muskrat@mindless.com>
## Corrected by roke
##

package Date::Language::Finnish;

use Date::Language ();
use vars qw(@ISA @DoW @DoWs @MoY @MoYs @AMPM @Dsuf %MoY %DoW $VERSION);
@ISA = qw(Date::Language);
$VERSION = "1.01";

# In Finnish, the names of the months and days are only capitalized at the beginning of sentences.
@MoY  = map($_ . "kuu", qw(tammi helmi maalis huhti touko kesä heinä elo syys loka marras joulu));
@DoW  = qw(sunnuntai maanantai tiistai keskiviikko torstai perjantai lauantai);

# it is not customary to use abbreviated names of months or days
# per Graham's suggestion:
@MoYs = @MoY;
@DoWs = @DoW;

# the short form of ordinals
@Dsuf = ('.') x 31;

# doesn't look like this is normally used...
@AMPM = qw(ap ip);


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