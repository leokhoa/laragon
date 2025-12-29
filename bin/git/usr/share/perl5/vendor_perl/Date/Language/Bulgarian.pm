##
## Bulgarian tables contributed by Krasimir Berov
##

package Date::Language::Bulgarian;
use strict;
use warnings;
use utf8;
use base qw(Date::Language);
our (@DoW, @DoWs, @MoY, @MoYs, @AMPM, @Dsuf, %MoY, %DoW, $VERSION);
$VERSION = "1.01";

@DoW = qw(неделя понеделник вторник сряда четвъртък петък събота);
@MoY = qw(януари февруари март април май юни
    юли август септември октомври ноември декември);
@DoWs = qw(нд пн вт ср чт пт сб);
@MoYs = map { substr($_,0,3) } @MoY;
@AMPM = qw(AM PM);

@Dsuf = (qw(ти ви ри ти ти ти ти ми ми ти)) x 3;
@Dsuf[11,12,13] = qw(ти ти ти);
@Dsuf[30,31] = qw(ти ви);

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
sub format_o { ($_[0]->[3]<10?' ':'').$_[0]->[3].$Dsuf[$_[0]->[3]] }

1;

__END__

=encoding utf8

=head1 NAME

Date::Language::Bulgarian - localization for Date::Format

=head1 DESCRIPTION

This is Bulgarian localization for Date::Format. 
It is important to note that this module source code is in utf8.
All strings which it outputs are in utf8, so it is safe to use it 
currently only with English. You are left alone to try and convert 
the output when using different Date::Language::* in the same application. 
This should be addresed in the future.

=head1 SYNOPSIS

    use strict; 
    use warnings;
    use Date::Language;
    local $\=$/;
    my $template ='%a %b %e %T %Y (%Y-%m-%d %H:%M:%S)';
    my $time=1290883821; #or just use time();
    my @lt = localtime($time);
    my %languages = qw(English GMT German EEST Bulgarian EET);
    binmode(select,':utf8');

    foreach my $l(keys %languages){
        my $lang = Date::Language->new($l);
        my $zone = $languages{$l};
        print $/. "$l $zone";
        print $lang->time2str($template, $time);
        print $lang->time2str($template, $time, $zone);

        print $lang->strftime($template, \@lt);
    }

=head1 AUTHOR

Krasimir Berov (berov@cpan.org)

=head1 COPYRIGHT

Copyright (c) 2010 Krasimir Berov. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut


