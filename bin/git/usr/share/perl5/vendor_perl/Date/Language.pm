
package Date::Language;

use     strict;
use     Time::Local;
use     Carp;
use     vars qw($VERSION @ISA);
require Date::Format;

$VERSION = "1.10";
@ISA     = qw(Date::Format::Generic);

sub new
{
 my $self = shift;
 my $type = shift || $self;

 $type =~ s/^(\w+)$/Date::Language::$1/;

 croak "Bad language"
	unless $type =~ /^[\w:]+$/;

 eval "require $type"
	or croak $@;

 bless [], $type;
}

# Stop AUTOLOAD being called ;-)
sub DESTROY {}

sub AUTOLOAD
{
 use vars qw($AUTOLOAD);

 if($AUTOLOAD =~ /::strptime\Z/o)
  {
   my $self = $_[0];
   my $type = ref($self) || $self;
   require Date::Parse;

   no strict 'refs';
   *{"${type}::strptime"} = Date::Parse::gen_parser(
	\%{"${type}::DoW"},
	\%{"${type}::MoY"},
	\@{"${type}::Dsuf"},
	1);

   goto &{"${type}::strptime"};
  }

 croak "Undefined method &$AUTOLOAD called";
}

sub str2time
{
 my $me = shift;
 my @t = $me->strptime(@_);

 return undef
	unless @t;

 my($ss,$mm,$hh,$day,$month,$year,$zone) = @t;
 my @lt  = localtime(time);

 $hh    ||= 0;
 $mm    ||= 0;
 $ss    ||= 0;

 $month = $lt[4]
	unless(defined $month);

 $day  = $lt[3]
	unless(defined $day);

 $year = ($month > $lt[4]) ? ($lt[5] - 1) : $lt[5]
	unless(defined $year);

 return defined $zone ? timegm($ss,$mm,$hh,$day,$month,$year) - $zone
    	    	      : timelocal($ss,$mm,$hh,$day,$month,$year);
}

1;

__END__


=head1 NAME

Date::Language - Language specific date formating and parsing

=head1 SYNOPSIS

  use Date::Language;

  my $lang = Date::Language->new('German');
  $lang->time2str("%a %b %e %T %Y\n", time);

=head1 DESCRIPTION

L<Date::Language> provides objects to parse and format dates for specific languages. Available languages are

  Afar                    French                  Russian_cp1251
  Amharic                 Gedeo                   Russian_koi8r
  Austrian                German                  Sidama
  Brazilian               Greek                   Somali
  Chinese                 Hungarian               Spanish
  Chinese_GB              Icelandic               Swedish
  Czech                   Italian                 Tigrinya
  Danish                  Norwegian               TigrinyaEritrean
  Dutch                   Oromo                   TigrinyaEthiopian
  English                 Romanian                Turkish
  Finnish                 Russian                 Bulgarian
  Occitan

=head1 METHODS

=over

=item time2str

See L<Date::Format/time2str>

=item strftime

See L<Date::Format/strftime>

=item ctime

See L<Date::Format/ctime>

=item asctime

See L<Date::Format/asctime>

=item str2time

See L<Date::Parse/str2time>

=item strptime

See L<Date::Parse/strptime>

=back

