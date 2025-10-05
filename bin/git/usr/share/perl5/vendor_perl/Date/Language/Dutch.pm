##
## Dutch tables
## Contributed by Johannes la Poutre <jlpoutre@corp.nl.home.com>
##

package Date::Language::Dutch;

use Date::Language ();
use vars qw(@ISA @DoW @DoWs @MoY @MoYs @AMPM @Dsuf %MoY %DoW $VERSION);
@ISA = qw(Date::Language);
$VERSION = "1.02";

@MoY  = qw(januari februari maart april mei juni juli
           augustus september oktober november december);
@MoYs = map(substr($_, 0, 3), @MoY);
$MoYs[2] = 'mrt'; # mrt is more common (Frank Maas)
@DoW  = map($_ . "dag", qw(zon maan dins woens donder vrij zater));
@DoWs = map(substr($_, 0, 2), @DoW);

# these aren't normally used...
@AMPM = qw(VM NM);
@Dsuf = ('e') x 31;


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
