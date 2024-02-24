# Copyright (c) 1995-2009 Graham Barr. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

package Date::Parse;

require 5.000;
use strict;
use vars qw($VERSION @ISA @EXPORT);
use Time::Local;
use Carp;
use Time::Zone;
use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(&strtotime &str2time &strptime);

$VERSION = "2.33";

my %month = (
	january		=> 0,
	february	=> 1,
	march		=> 2,
	april		=> 3,
	may		=> 4,
	june		=> 5,
	july		=> 6,
	august		=> 7,
	september	=> 8,
	sept		=> 8,
	october		=> 9,
	november	=> 10,
	december	=> 11,
	);

my %day = (
	sunday		=> 0,
	monday		=> 1,
	tuesday		=> 2,
	tues		=> 2,
	wednesday	=> 3,
	wednes		=> 3,
	thursday	=> 4,
	thur		=> 4,
	thurs		=> 4,
	friday		=> 5,
	saturday	=> 6,
	);

my @suf = (qw(th st nd rd th th th th th th)) x 3;
@suf[11,12,13] = qw(th th th);

#Abbreviations

map { $month{substr($_,0,3)} = $month{$_} } keys %month;
map { $day{substr($_,0,3)}   = $day{$_} }   keys %day;

my $strptime = <<'ESQ';
 my %month = map { lc $_ } %$mon_ref;
 my $daypat = join("|", map { lc $_ } reverse sort keys %$day_ref);
 my $monpat = join("|", reverse sort keys %month);
 my $sufpat = join("|", reverse sort map { lc $_ } @$suf_ref);

 my %ampm = (
	'a' => 0,  # AM
	'p' => 12, # PM
	);

 my($AM, $PM) = (0,12);

sub {

  my $dtstr = lc shift;
  my $merid = 24;

  my($century,$year,$month,$day,$hh,$mm,$ss,$zone,$dst,$frac);

  $zone = tz_offset(shift) if @_;

  1 while $dtstr =~ s#\([^\(\)]*\)# #o;

  $dtstr =~ s#(\A|\n|\Z)# #sog;

  # ignore day names
  $dtstr =~ s#([\d\w\s])[\.\,]\s#$1 #sog;
  $dtstr =~ s/,/ /g;
  $dtstr =~ s#($daypat)\s*(den\s)?\b# #o;
  # Time: 12:00 or 12:00:00 with optional am/pm

  return unless $dtstr =~ /\S/;
  
  if ($dtstr =~ s/\s(\d{4})([-:]?)(\d\d?)\2(\d\d?)(?:[-Tt ](\d\d?)(?:([-:]?)(\d\d?)(?:\6(\d\d?)(?:[.,](\d+))?)?)?)?(?=\D)/ /) {
    ($year,$month,$day,$hh,$mm,$ss,$frac) = ($1,$3-1,$4,$5,$7,$8,$9);
  }

  unless (defined $hh) {
    if ($dtstr =~ s#[:\s](\d\d?):(\d\d?)(:(\d\d?)(?:\.\d+)?)?(z)?\s*(?:([ap])\.?m?\.?)?\s# #o) {
      ($hh,$mm,$ss) = ($1,$2,$4);
      $zone = 0 if $5;
      $merid = $ampm{$6} if $6;
    }

    # Time: 12 am
    
    elsif ($dtstr =~ s#\s(\d\d?)\s*([ap])\.?m?\.?\s# #o) {
      ($hh,$mm,$ss) = ($1,0,0);
      $merid = $ampm{$2};
    }
  }
    
  if (defined $hh and $hh <= 12 and $dtstr =~ s# ([ap])\.?m?\.?\s# #o) {
    $merid = $ampm{$1};
  }


  unless (defined $year) {
    # Date: 12-June-96 (using - . or /)
    
    if ($dtstr =~ s#\s(\d\d?)([\-\./])($monpat)(\2(\d\d+))?\s# #o) {
      ($month,$day) = ($month{$3},$1);
      $year = $5 if $5;
    }
    
    # Date: 12-12-96 (using '-', '.' or '/' )
    
    elsif ($dtstr =~ s#\s(\d+)([\-\./])(\d\d?)(\2(\d+))?\s# #o) {
      ($month,$day) = ($1 - 1,$3);

      if ($5) {
	$year = $5;
	# Possible match for 1995-01-24 (short mainframe date format);
	($year,$month,$day) = ($1, $3 - 1, $5) if $month > 12;
	return if length($year) > 2 and $year < 1901;
      }
    }
    elsif ($dtstr =~ s#\s(\d+)\s*($sufpat)?\s*($monpat)# #o) {
      ($month,$day) = ($month{$3},$1);
    }
    elsif ($dtstr =~ s#($monpat)\s*(\d+)\s*($sufpat)?\s# #o) {
      ($month,$day) = ($month{$1},$2);
    }
    elsif ($dtstr =~ s#($monpat)([\/-])(\d+)[\/-]# #o) {
      ($month,$day) = ($month{$1},$3);
    }

    # Date: 961212

    elsif ($dtstr =~ s#\s(\d\d)(\d\d)(\d\d)\s# #o) {
      ($year,$month,$day) = ($1,$2-1,$3);
    }

    $year = $1 if !defined($year) and $dtstr =~ s#\s(\d{2}(\d{2})?)[\s\.,]# #o;

  }

  # Zone

  $dst = 1 if $dtstr =~ s#\bdst\b##o;

  if ($dtstr =~ s#\s"?([a-z]{3,4})(dst|\d+[a-z]*|_[a-z]+)?"?\s# #o) {
    $dst = 1 if $2 and $2 eq 'dst';
    $zone = tz_offset($1);
    return unless defined $zone;
  }
  elsif ($dtstr =~ s#\s([a-z]{3,4})?([\-\+]?)-?(\d\d?):?(\d\d)?(00)?\s# #o) {
    my $m = defined($4) ? "$2$4" : 0;
    my $h = "$2$3";
    $zone = defined($1) ? tz_offset($1) : 0;
    return unless defined $zone;
    $zone += 60 * ($m + (60 * $h));
  }

  if ($dtstr =~ /\S/) {
    # now for some dumb dates
    if ($dtstr =~ s/^\s*(ut?|z)\s*$//) {
      $zone = 0;
    }
    elsif ($dtstr =~ s#\s([a-z]{3,4})?([\-\+]?)-?(\d\d?)(\d\d)?(00)?\s# #o) {
      my $m = defined($4) ? "$2$4" : 0;
      my $h = "$2$3";
      $zone = defined($1) ? tz_offset($1) : 0;
      return unless defined $zone;
      $zone += 60 * ($m + (60 * $h));
    }

    return if $dtstr =~ /\S/o;
  }

  if (defined $hh) {
    if ($hh == 12) {
      $hh = 0 if $merid == $AM;
    }
    elsif ($merid == $PM) {
      $hh += 12;
    }
  }

  if (defined $year && $year > 1900) {
    $century = int($year / 100);
    $year -= 1900;
  }

  $zone += 3600 if defined $zone && $dst;
  $ss += "0.$frac" if $frac;

  return ($ss,$mm,$hh,$day,$month,$year,$zone,$century);
}
ESQ

use vars qw($day_ref $mon_ref $suf_ref $obj);

sub gen_parser
{
 local($day_ref,$mon_ref,$suf_ref,$obj) = @_;

 if($obj)
  {
   my $obj_strptime = $strptime;
   substr($obj_strptime,index($strptime,"sub")+6,0) = <<'ESQ';
 shift; # package
ESQ
   my $sub = eval "$obj_strptime" or die $@;
   return $sub;
  }

 eval "$strptime" or die $@;

}

*strptime = gen_parser(\%day,\%month,\@suf);

sub str2time
{
 my @t = strptime(@_);

 return undef
	unless @t;

 my($ss,$mm,$hh,$day,$month,$year,$zone, $century) = @t;
 my @lt  = localtime(time);

 $hh    ||= 0;
 $mm    ||= 0;
 $ss    ||= 0;

 my $frac = $ss - int($ss);
 $ss = int $ss;

 $month = $lt[4]
	unless(defined $month);

 $day  = $lt[3]
	unless(defined $day);

 $year = ($month > $lt[4]) ? ($lt[5] - 1) : $lt[5]
	unless(defined $year);

 # we were given a 4 digit year, so let's keep using those
 $year += 1900 if defined $century;

 return undef
	unless($month <= 11 && $day >= 1 && $day <= 31
		&& $hh <= 23 && $mm <= 59 && $ss <= 59);

 my $result;

 if (defined $zone) {
   $result = eval {
     local $SIG{__DIE__} = sub {}; # Ick!
     timegm($ss,$mm,$hh,$day,$month,$year);
   };
   return undef
     if !defined $result
        or $result == -1
           && join("",$ss,$mm,$hh,$day,$month,$year)
     	        ne "595923311169";
   $result -= $zone;
 }
 else {
   $result = eval {
     local $SIG{__DIE__} = sub {}; # Ick!
     timelocal($ss,$mm,$hh,$day,$month,$year);
   };
   return undef
     if !defined $result
        or $result == -1
           && join("",$ss,$mm,$hh,$day,$month,$year)
     	        ne join("",(localtime(-1))[0..5]);
 }

 return $result + $frac;
}

1;

__END__


=head1 NAME

Date::Parse - Parse date strings into time values

=head1 SYNOPSIS

	use Date::Parse;
	
	$time = str2time($date);
	
	($ss,$mm,$hh,$day,$month,$year,$zone) = strptime($date);

=head1 DESCRIPTION

C<Date::Parse> provides two routines for parsing date strings into time values.

=over 4

=item str2time(DATE [, ZONE])

C<str2time> parses C<DATE> and returns a unix time value, or undef upon failure.
C<ZONE>, if given, specifies the timezone to assume when parsing if the
date string does not specify a timezone.

=item strptime(DATE [, ZONE])

C<strptime> takes the same arguments as str2time but returns an array of
values C<($ss,$mm,$hh,$day,$month,$year,$zone,$century)>. Elements are only
defined if they could be extracted from the date string. The C<$zone> element
is the timezone offset in seconds from GMT. An empty array is returned upon
failure.

=back

=head1 MULTI-LANGUAGE SUPPORT

Date::Parse is capable of parsing dates in several languages, these include
English, French, German and Italian.

	$lang = Date::Language->new('German');
	$lang->str2time("25 Jun 1996 21:09:55 +0100");

=head1 EXAMPLE DATES

Below is a sample list of dates that are known to be parsable with Date::Parse

 1995:01:24T09:08:17.1823213           ISO-8601
 1995-01-24T09:08:17.1823213
 Wed, 16 Jun 94 07:29:35 CST           Comma and day name are optional 
 Thu, 13 Oct 94 10:13:13 -0700
 Wed, 9 Nov 1994 09:50:32 -0500 (EST)  Text in ()'s will be ignored.
 21 dec 17:05                          Will be parsed in the current time zone
 21-dec 17:05
 21/dec 17:05
 21/dec/93 17:05
 1999 10:02:18 "GMT"
 16 Nov 94 22:28:20 PST 

=head1 LIMITATION

Date::Parse uses L<Time::Local> internally, so is limited to only parsing dates
which result in valid values for Time::Local::timelocal. This generally means dates
between 1901-12-17 00:00:00 GMT and 2038-01-16 23:59:59 GMT

=head1 BUGS

When both the month and the date are specified in the date as numbers
they are always parsed assuming that the month number comes before the
date. This is the usual format used in American dates.

The reason why it is like this and not dynamic is that it must be
deterministic. Several people have suggested using the current locale,
but this will not work as the date being parsed may not be in the format
of the current locale.

My plans to address this, which will be in a future release, is to allow
the programmer to state what order they want these values parsed in.

=head1 AUTHOR

Graham Barr <gbarr@pobox.com>

=head1 COPYRIGHT

Copyright (c) 1995-2009 Graham Barr. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

