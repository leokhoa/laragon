##
## Italian tables
##

package Date::Language::Italian;

use Date::Language ();
use vars qw(@ISA @DoW @DoWs @MoY @MoYs @AMPM @Dsuf %MoY %DoW $VERSION);
@ISA = qw(Date::Language);
$VERSION = "1.01";

@MoY  = qw(Gennaio Febbraio Marzo Aprile Maggio Giugno
	   Luglio Agosto Settembre Ottobre Novembre Dicembre);
@MoYs = qw(Gen Feb Mar Apr Mag Giu Lug Ago Set Ott Nov Dic);
@DoW  = qw(Domenica Lunedi Martedi Mercoledi Giovedi Venerdi Sabato);
@DoWs = qw(Dom Lun Mar Mer Gio Ven Sab);

use Date::Language::English ();
@AMPM =   @{Date::Language::English::AMPM};
@Dsuf =   @{Date::Language::English::Dsuf};

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
