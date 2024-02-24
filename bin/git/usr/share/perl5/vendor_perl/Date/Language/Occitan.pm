##
## Occitan tables, contributed by Quentn PAGÈS
##

package Date::Language::Occitan;

use Date::Language ();
use vars qw(@ISA @DoW @DoWs @MoY @MoYs @AMPM @Dsuf %MoY %DoW $VERSION);
@ISA = qw(Date::Language);
$VERSION = "1.04";

@DoW = qw(dimenge diluns dimars dimècres dijòus divendres dissabte);
@MoY = qw(genièr febrièr mars abrial mai junh 
          julhet agost octòbre novembre decembre);
@DoWs = map { substr($_,0,3) } @DoW;
@MoYs = map { substr($_,0,3) } @MoY;
$MoYs[6] = 'jul';
@AMPM = qw(AM PM);

@Dsuf = ((qw(er e e e e e e e e e)) x 3, 'er');

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
