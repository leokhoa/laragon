#!/usr/bin/perl -w

=encoding UTF-8

=head1 NAME

debinhex.pl - use Convert::BinHex to decode BinHex files


=head1 USAGE

Usage:

    debinhex.pl [options] file ... file
     
Where the options are:

    -o dir    Output in given directory (default outputs in file's directory)
    -v        Verbose output (normally just one line per file is shown)

=head1 DESCRIPTION

Each file is expected to be a BinHex file.  By default, the output file is
given the name that the BinHex file dictates, regardless of the name of
the BinHex file.


=head1 WARNINGS

Largely untested.


=head1 AUTHORS

Paul J. Schinder (NASA/GSFC) mostly, though Eryq can't seem to keep
his grubby paws off anything...

Sören M. Andersen (somian), made it actually work under Perl 5.8.7 on MSWin32.

=cut

our $VERSION = '1.125'; # VERSION

my $The_OS;
BEGIN { $The_OS = $^O ? $^O : q// }
eval { require Mac::Files } if ($The_OS eq "MacOS");

use Getopt::Std;				 
use Convert::BinHex;
use POSIX;
use Fcntl;
use File::Basename;
use Carp;

use strict;
use vars qw(
            $opt_o
            $opt_v
);

my $DEBUG = 0;

#------------------------------------------------------------
# main
#------------------------------------------------------------
sub main {

    # What usage?
    @ARGV or usage();
    getopts('o:v');
    $DEBUG = $opt_v;

    # Process files:
    my $file;
    foreach $file (@ARGV) {
	debinhex($file);
    }
}
exit(&main ? 0 : -1);

#------------------------------------------------------------
# usage
#------------------------------------------------------------
# Get usage from me.

sub usage {
    my $msg = shift || '';
    my $usage = '';
    if (open(USAGE, "<$0")) {
        while (defined($_ = <USAGE>) and !/^=head1 USAGE/) {};
        while (defined($_ = <USAGE>) and !/^=head1/) {$usage .= $_};
        close USAGE;
    }
    else {
        $usage = "Usage unavailable; please see the script itself.";
    }
    print STDERR "\n$msg$usage";
    exit -1;
}

#------------------------------------------------------------
# debinhex FILE
#------------------------------------------------------------
# Decode the given FILE.
#
sub debinhex {
    my $inpath = shift || croak("No filename given $!");
    local *BHEX;
    my ($data, $testlength, $length, $fd);

    print "DeBinHexing: $inpath\n";

    # Open BinHex file:
    open(BHEX,"<$inpath") || croak("Unable to open $inpath: $!");
    binmode BHEX;

    # Create converter interface on stream:
    my $hqx = Convert::BinHex->open(FH => \*BHEX);

    # Read header, and output as string if debugging:
    $hqx->read_header;
    print $hqx->header_as_string if $DEBUG;

    # Get output directory/filename:
    my ($inname, $indir) = fileparse($inpath);
    my $outname = $hqx->filename || 'NONAME';
    my $outdir  = $opt_o || $indir;
    my $outpath = "$outdir/$outname"; $outpath =~ s{/+}{/}g;

    # Create Mac file:
    if ($The_OS eq "MacOS") {
        Mac::Files::FSpCreate($outpath, $hqx->creator, $hqx->type)
           or croak("Unable to create Mac file $outpath");
    }

    # Get lengths of forks:
    my $dlength = $hqx->data_length;
    my $rlength = $hqx->resource_length;

    # Write data fork:
    print "Writing:     $outpath\n";
    $fd = POSIX::open($outpath, (&POSIX::O_WRONLY | &POSIX::O_CREAT | &Fcntl::O_BINARY), 0755);
    $testlength = 0;
    while (defined($data = $hqx->read_data)) {
        $length = length($data);
        POSIX::write($fd, $data, $length)
	    or croak("couldn't write $length bytes: $!");
        $testlength += $length;
    }
    POSIX::close($fd) or croak "Unable to close $outpath";
    croak("Data fork length mismatch: ".
	  "expected $dlength, wrote $testlength")
        if $dlength != $testlength;

    # Write resource fork?
    if ($rlength) {

	# Determine how to open fork file appropriately:
	my ($rpath, $rflags);
        if ($The_OS eq "MacOS") {
	    $rpath  = $outpath;
	    $rflags = (&POSIX::O_WRONLY | &POSIX::O_CREAT | &Fcntl::O_RSRC);
        } 
	else {
	    $rpath  = "$outpath.rsrc";
	    $rflags = (&POSIX::O_WRONLY | &POSIX::O_CREAT | &Fcntl::O_BINARY);
        }	

	# Write resource fork...
	$fd = POSIX::open($rpath, $rflags, 0755);
        $testlength = 0;
        while (defined($data = $hqx->read_resource)) {
            $length = length($data);
	    POSIX::write($fd,$data,$length)
		or croak "Couldn't write $length bytes: $!";
            $testlength += $length;
        }
        POSIX::close($fd) or croak "Unable to close $rpath";
        croak("Resource fork length mismatch: ".
	      "expected $rlength, wrote $testlength")
	    if $testlength != $rlength;
    }

    # Set Mac attributes:
    if ($The_OS eq "MacOS") {
        my $has = Mac::Files::FSpGetCatInfo($outpath);
        my $finfo = $has->{ioFlFndrInfo};
        $finfo->{fdFlags}   = $hqx->flags & 0xfeff; #turn off inited bit
        $finfo->{fdType}    = $hqx->type || "????";
        $finfo->{fdCreator} = $hqx->creator || "????";

        # Turn on the bundle bit if it's an application:
###     $finfo->{fdFlags} |= 0x2000 if $finfo->{fdType} eq "APPL";

        if ($DEBUG) {
            printf("%x\n",$finfo->{fdFlags});
            printf("%s\n",$finfo->{fdType});
            printf("%s\n",$finfo->{fdCreator});
        }
        $has->{ioFlFndrInfo} = $finfo;
        Mac::Files::FSpSetCatInfo($outpath, $has)
        	or croak "Unable to set catalog info $^E";
        if ($DEBUG) {
            $has = Mac::Files::FSpGetCatInfo ($outpath);
            printf("%x\n",$has->{ioFlFndrInfo}->{fdFlags});
            printf("%s\n",$has->{ioFlFndrInfo}->{fdType});
            printf("%s\n",$has->{ioFlFndrInfo}->{fdCreator});
        }
    }
    1;
}

#------------------------------------------------------------
__END__
# Last modified: 16 Feb 2006 at 05:16 PM EST
