##
## English tables
##

package Date::Language::Chinese;

use Date::Language ();
use vars qw(@ISA @DoW @DoWs @MoY @MoYs @AMPM @Dsuf %MoY %DoW $VERSION);
@ISA = qw(Date::Language);
$VERSION = "1.00";

@DoW = qw(星期日 星期一 星期二 星期三 星期四 星期五 星期六);
@MoY = qw(一月 二月 三月 四月 五月 六月
	  七月 八月 九月 十月 十一月 十二月);
@DoWs = map { $_ } @DoW;
@MoYs = map { $_ } @MoY;
@AMPM = qw(上午 下午);

@Dsuf = (qw(日 日 日 日 日 日 日 日 日 日)) x 3;

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

sub format_o { sprintf("%2d%s",$_[0]->[3],"日") }
1;
