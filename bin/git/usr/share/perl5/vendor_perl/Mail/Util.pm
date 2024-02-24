# Copyrights 1995-2019 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of the bundle MailTools.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md for Copyright.
# Licensed under the same terms as Perl itself.

package Mail::Util;
use vars '$VERSION';
$VERSION = '2.21';

use base 'Exporter';

use strict;
use Carp;

our @EXPORT_OK = qw(read_mbox maildomain mailaddress);

sub Version { our $VERSION }

my ($domain, $mailaddress);
my @sendmailcf = qw(/etc /etc/sendmail /etc/ucblib
    /etc/mail /usr/lib /var/adm/sendmail);


sub read_mbox($)
{   my $file  = shift;

    local *FH;
    open FH,'<', $file
	or croak "cannot open '$file': $!\n";

    local $_;
    my @mbox;
    my $mail  = [];
    my $blank = 1;

    while(<FH>)
    {   if($blank && /^From .*\d{4}/)
        {   push @mbox, $mail if @$mail;
            $mail  = [ $_ ];
            $blank = 0;
        }
        else
        {   $blank = m/^$/ ? 1 : 0;
            push @$mail, $_;
        }
    }

    push @mbox, $mail if @$mail;
    close FH;

    wantarray ? @mbox : \@mbox;
}


sub maildomain()
{   return $domain
	if defined $domain;

    $domain = $ENV{MAILDOMAIN}
        and return $domain;

    # Try sendmail configuration file

    my $config = (grep -r, map {"$_/sendmail.cf"} @sendmailcf)[0];

    local *CF;
    local $_;
    if(defined $config && open CF, '<', $config)
    {   my %var;
	while(<CF>)
        {   if(my ($v, $arg) = /^D([a-zA-Z])([\w.\$\-]+)/)
            {   $arg =~ s/\$([a-zA-Z])/exists $var{$1} ? $var{$1} : '$'.$1/eg;
		$var{$v} = $arg;
	    }
	}
	close CF;
	$domain = $var{j} if defined $var{j};
	$domain = $var{M} if defined $var{M};

        $domain = $1
            if $domain && $domain =~ m/([A-Za-z0-9](?:[\.\-A-Za-z0-9]+))/;

	return $domain
	    if defined $domain && $domain !~ /\$/;
    }

    # Try smail config file if exists

    if(open CF, '<', "/usr/lib/smail/config")
    {   while(<CF>)
        {   if( /\A\s*hostnames?\s*=\s*(\S+)/ )
            {   $domain = (split /\:/,$1)[0];
		last;
	    }
	}
	close CF;

	return $domain
	    if defined $domain;
    }

    # Try a SMTP connection to 'mailhost'

    if(eval {require Net::SMTP})
    {   foreach my $host (qw(mailhost localhost))
        {   # hosts are local, so short timeout
            my $smtp = eval { Net::SMTP->new($host, Timeout => 5) };
	    if(defined $smtp)
            {   $domain = $smtp->domain;
		$smtp->quit;
		last;
	    }
	}
    }

    # Use internet(DNS) domain name, if it can be found
    $domain = Net::Domain::domainname()
        if !defined $domain && eval {require Net::Domain};

    $domain ||= "localhost";
}


sub mailaddress(;$)
{   $mailaddress = shift if @_;

    return $mailaddress
        if defined $mailaddress;

    # Get user name from environment
    $mailaddress = $ENV{MAILADDRESS};

    unless($mailaddress || $^O ne 'MacOS')
    {   require Mac::InternetConfig;

        no strict;
	Mac::InternetConfig->import;
	$mailaddress = $InternetConfig{kICEmail()};
    }

    $mailaddress ||= $ENV{USER} || $ENV{LOGNAME} || eval {getpwuid $>}
                 ||  "postmaster";

    # Add domain if it does not exist
    $mailaddress .= '@' . maildomain
	if $mailaddress !~ /\@/;

    $mailaddress =~ s/(^.*<|>.*$)//g;
    $mailaddress;
}

1;
