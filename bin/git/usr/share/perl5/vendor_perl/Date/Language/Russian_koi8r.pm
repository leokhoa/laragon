##
## Russian koi8r
##

package Date::Language::Russian_koi8r;

use Date::Language ();
use vars qw(@ISA @DoW @DoWs @MoY @MoYs @AMPM @Dsuf %MoY %DoW $VERSION);
@ISA = qw(Date::Language);
$VERSION = "1.01";

@DoW = qw(Воскресенье Понедельник Вторник Среда Четверг Пятница Суббота);
@MoY = qw(Январь Февраль Март Апрель Май Июнь
      Июль Август Сентябрь Октябрь Ноябрь Декабрь);
@DoWs = qw(Вск Пнд Втр Срд Чтв Птн Сбт);
#@DoWs = map { substr($_,0,3) } @DoW;
@MoYs = map { substr($_,0,3) } @MoY;
@AMPM = qw(AM PM);

@Dsuf = ('e') x 31;
#@Dsuf[11,12,13] = qw(е е е);
#@Dsuf[30,31] = qw(е е);

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
