#!/usr/bin/perl -w


=head1 NAME

binhex.pl - use Convert::BinHex to encode files as BinHex 


=head1 USAGE

Usage:

    binhex.pl [options] file ... file
     
Where the options are:

    -o dir    Output in given directory (default outputs in file's directory)
    -v        Verbose output (normally just one line per file is shown)

=head1 DESCRIPTION

Each file is converted to file.hqx.


=head1 WARNINGS

Largely untested.


=head1 AUTHOR

Paul J. Schinder (NASA/GSFC) mostly, though Eryq can't seem to keep
his grubby paws off anything...


=cut

use lib "./lib";

use Getopt::Std;
use Convert::BinHex;
use POSIX;
use Fcntl;
use File::Basename;
use Carp;
require Mac::Files if (($^O||'') eq "MacOS");

our $VERSION = '1.125'; # VERSION

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
	binhex($file);
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
        while ($_ = <USAGE> and !/^=head1 USAGE/) {};
        while ($_ = <USAGE> and !/^=head1/) {$usage .= $_};
        close USAGE;
    }
    else {
        $usage = "Usage unavailable; please see the script itself.";
    }
    print STDERR "\n$msg$usage";
    exit -1;
}

#------------------------------------------------------------
# binhex FILE
#------------------------------------------------------------
# Encode the given FILE.
#
sub binhex {
    my $inpath = shift || die "No filename given $!";
    local *BHEX;
    my ($has, $dlength, $rlength, $finfo, $flags);

    # Create new BinHex interface:
    my $hqx = Convert::BinHex->new;

    # Get input directory/filename:
    my ($inname, $indir) = fileparse($inpath);
    die "filename $inname too long!" if ((length($inname)+4) > 31);
    $hqx->filename($inname);

    # Set up output directory/filename:
    my $outname = "$inname.hqx";
    my $outdir  = $opt_o || $indir;
    my $outpath = "$outdir/$outname"; $outpath =~ s{/+}{/}g;
    
    # If we're on a Mac, we can get the real resource info:
    if ($^O||'' eq "MacOS") {

	# Get and set up type, creator, flags:
    	$has  = Mac::Files::FSpGetCatInfo($inpath);
        $finfo   = $has->{ioFlFndrInfo};
        $dlength = $has->{ioFlLgLen};
        $rlength = $has->{ioFlRLgLen};
        $hqx->type($finfo->{fdType});
        $hqx->creator($finfo->{fdCreator});
        $hqx->flags($finfo->{fdFlags} & 0xfeff);     # turn off inited bit

	# Set up data fork:
        $hqx->data(Path=>$inpath);
    	$hqx->data->length($dlength);

	# Set up resource fork:
    	$hqx->resource(Path=>$inpath, Fork => "RSRC");
    	$hqx->resource->length($rlength);
    } 
    else {                      # not a Mac: fake it...
	# Set up data fork:
        $hqx->data(Path => $inpath);
	$dlength  = (-s $inpath);

	# Set up resource fork:
	if (-e "$inpath.rsrc") { 
	    $hqx->resource(Path => "$inpath.rsrc");
	    $rlength = (-s "$inpath.rsrc");
	}
	else { 
	    $hqx->resource(Data => '');
	    $rlength = 0;
	}
    }

    # Ready!
    print "BinHexing: $inpath\n";
    if ($DEBUG) {
    	print "   Resource size:   $rlength\n"     if defined($rlength);
	print "   Data size:       $dlength\n"     if defined($dlength);
    }
    open BHEX, ">$outpath" or croak("Unable to open $outpath");
    $hqx->encode(\*BHEX);
    close BHEX;
    print "Wrote:     $outpath\n";
}
#------------------------------------------------------------
1;




