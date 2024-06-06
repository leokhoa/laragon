package File::Listing;

use strict;
use warnings;
use Carp ();
use HTTP::Date qw(str2time);
use Exporter 5.57 qw( import );

# ABSTRACT: Parse directory listing
our $VERSION = '6.15'; # VERSION

sub Version { $File::Listing::VERSION; }

our @EXPORT = qw(parse_dir);

sub parse_dir ($;$$$)
{
   my($dir, $tz, $fstype, $error) = @_;

   $fstype ||= 'unix';
   $fstype = "File::Listing::" . lc $fstype;

   my @args = $_[0];
   push(@args, $tz) if(@_ >= 2);
   push(@args, $error) if(@_ >= 4);

   $fstype->parse(@args);
}


sub line { Carp::croak("Not implemented yet"); }
sub init { } # Dummy sub


sub file_mode ($)
{
    Carp::croak("Input to file_mode() must be a 10 character string.")
        unless length($_[0]) == 10;

    # This routine was originally borrowed from Graham Barr's
    # Net::FTP package.

    local $_ = shift;
    my $mode = 0;
    my($type);

    s/^(.)// and $type = $1;

    # When the set-group-ID bit (file mode bit 02000) is set, and the group
    # execution bit (file mode bit 00020) is unset, and it is a regular file,
    # some implementations of `ls' use the letter `S', others use `l' or `L'.
    # Convert this `S'.

    s/[Ll](...)$/S$1/;

    while (/(.)/g) {
        $mode <<= 1;
        $mode |= 1 if $1 ne "-" &&
                      $1 ne "*" &&
                      $1 ne 'S' &&
                      $1 ne 'T';
    }

    $mode |= 0004000 if /^..s....../i;
    $mode |= 0002000 if /^.....s.../i;
    $mode |= 0001000 if /^........t/i;

    # De facto standard definitions. From 'stat.h' on Solaris 9.

    $type eq "p" and $mode |= 0010000 or        # fifo
    $type eq "c" and $mode |= 0020000 or        # character special
    $type eq "d" and $mode |= 0040000 or        # directory
    $type eq "b" and $mode |= 0060000 or        # block special
    $type eq "-" and $mode |= 0100000 or        # regular
    $type eq "l" and $mode |= 0120000 or        # symbolic link
    $type eq "s" and $mode |= 0140000 or        # socket
    $type eq "D" and $mode |= 0150000 or        # door
      Carp::croak("Unknown file type: $type");

    $mode;
}


sub parse
{
   my($pkg, $dir, $tz, $error) = @_;

   # First let's try to determine what kind of dir parameter we have
   # received.  We allow both listings, reference to arrays and
   # file handles to read from.

   if (ref($dir) eq 'ARRAY') {
       # Already split up
   }
   elsif (ref($dir) eq 'GLOB') {
       # A file handle
   }
   elsif (ref($dir)) {
      Carp::croak("Illegal argument to parse_dir()");
   }
   elsif ($dir =~ /^\*\w+(::\w+)+$/) {
      # This scalar looks like a file handle, so we assume it is
   }
   else {
      # A normal scalar listing
      $dir = [ split(/\n/, $dir) ];
   }

   $pkg->init();

   my @files = ();
   if (ref($dir) eq 'ARRAY') {
       for (@$dir) {
           push(@files, $pkg->line($_, $tz, $error));
       }
   }
   else {
       local($_);
       while (my $line = <$dir>) {
           chomp $line;
           push(@files, $pkg->line($line, $tz, $error));
       }
   }
   wantarray ? @files : \@files;  ## no critic (Community::Wantarray)
}



package File::Listing::unix;

use HTTP::Date qw(str2time);

our @ISA = qw(File::Listing);

# A place to remember current directory from last line parsed.
our $curdir;

sub init
{
    $curdir = '';
}


sub line
{
    shift; # package name
    local($_) = shift;
    my($tz, $error) = @_;

    s/\015//g;
    #study;

    my ($kind, $size, $date, $name);
    if (($kind, $size, $date, $name) =
        /^([\-\*FlrwxsStTdD]{10})                 # Type and permission bits
         .*                                       # Graps
         \D(\d+)                                  # File size
         \s+                                      # Some space
         (\w{3}\s+\d+\s+(?:\d{1,2}:\d{2}|\d{4})|\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2})  # Date
         \s+                                      # Some more space
         (.*)$                                    # File name
        /x )

    {
        return if $name eq '.' || $name eq '..';
        $name = "$curdir/$name" if length $curdir;
        my $type = '?';
        if ($kind =~ /^l/ && $name =~ /(.*) -> (.*)/ ) {
            $name = $1;
            $type = "l $2";
        }
        elsif ($kind =~ /^[\-F]/) { # (hopefully) a regular file
            $type = 'f';
        }
        elsif ($kind =~ /^[dD]/) {
            $type = 'd';
            $size = undef;  # Don't believe the reported size
        }
        return [$name, $type, $size, str2time($date, $tz),
              File::Listing::file_mode($kind)];

    }
    elsif (/^(.+):$/ && !/^[dcbsp].*\s.*\s.*:$/ ) {
        my $dir = $1;
        return () if $dir eq '.';
        $curdir = $dir;
        return ();
    }
    elsif (/^[Tt]otal\s+(\d+)$/ || /^\s*$/) {
        return ();
    }
    elsif (/not found/    || # OSF1, HPUX, and SunOS return
             # "$file not found"
             /No such file/ || # IRIX returns
             # "UX:ls: ERROR: Cannot access $file: No such file or directory"
                               # Solaris returns
             # "$file: No such file or directory"
             /cannot find/     # Windows NT returns
             # "The system cannot find the path specified."
             ) {
        return () unless defined $error;
        &$error($_) if ref($error) eq 'CODE';
        warn "Error: $_\n" if $error eq 'warn';
        return ();
    }
    elsif ($_ eq '') {       # AIX, and Linux return nothing
        return () unless defined $error;
        &$error("No such file or directory") if ref($error) eq 'CODE';
        warn "Warning: No such file or directory\n" if $error eq 'warn';
        return ();
    }
    else {
        # parse failed, check if the dosftp parse understands it
        File::Listing::dosftp->init();
        return(File::Listing::dosftp->line($_,$tz,$error));
    }

}



package File::Listing::dosftp;

use HTTP::Date qw(str2time);

our @ISA = qw(File::Listing);

# A place to remember current directory from last line parsed.
our $curdir;



sub init
{
    $curdir = '';
}


sub line
{
    shift; # package name
    local($_) = shift;
    my($tz, $error) = @_;

    s/\015//g;

    my ($date, $size_or_dir, $name, $size);

    # 02-05-96  10:48AM                 1415 src.slf
    # 09-10-96  09:18AM       <DIR>          sl_util
    if (($date, $size_or_dir, $name) =
        /^(\d\d-\d\d-\d\d\s+\d\d:\d\d\wM)         # Date and time info
         \s+                                      # Some space
         (<\w{3}>|\d+)                            # Dir or Size
         \s+                                      # Some more space
         (.+)$                                    # File name
        /x )
    {
        return if $name eq '.' || $name eq '..';
        $name = "$curdir/$name" if length $curdir;
        my $type = '?';
        if ($size_or_dir eq '<DIR>') {
            $type = "d";
            $size = ""; # directories have no size in the pc listing
        }
        else {
            $type = 'f';
            $size = $size_or_dir;
        }
        return [$name, $type, $size, str2time($date, $tz), undef];
    }
    else {
        return () unless defined $error;
        &$error($_) if ref($error) eq 'CODE';
        warn "Can't parse: $_\n" if $error eq 'warn';
        return ();
    }

}



package File::Listing::vms;
our @ISA = qw(File::Listing);

package File::Listing::netware;
our @ISA = qw(File::Listing);



package File::Listing::apache;

our @ISA = qw(File::Listing);


sub init { }


sub line {
    shift; # package name
    local($_) = shift;
    my($tz, $error) = @_; # ignored for now...

    s!</?t[rd][^>]*>! !g;  # clean away various table stuff
    if (m!<A\s+HREF=\"([^?\"]+)\">.*</A>.*?(\d+)-([a-zA-Z]+|\d+)-(\d+)\s+(\d+):(\d+)\s+(?:([\d\.]+[kMG]?|-))!i) {
        my($filename, $filesize) = ($1, $7);
        my($d,$m,$y, $H,$M) = ($2,$3,$4,$5,$6);
        if ($m =~ /^\d+$/) {
            ($d,$y) = ($y,$d) # iso date
        }
        else {
            $m = _monthabbrev_number($m);
        }

        $filesize = 0 if $filesize eq '-';
        if ($filesize =~ s/k$//i) {
            $filesize *= 1024;
        }
        elsif ($filesize =~ s/M$//) {
            $filesize *= 1024*1024;
        }
        elsif ($filesize =~ s/G$//) {
            $filesize *= 1024*1024*1024;
        }
        $filesize = int $filesize;

        require Time::Local;
        my $filetime = Time::Local::timelocal(0,$M,$H,$d,$m-1,_guess_year($y));
        my $filetype = ($filename =~ s|/$|| ? "d" : "f");
        return [$filename, $filetype, $filesize, $filetime, undef];
    }

    # the default listing doesn't include timestamps or file sizes
    # but we don't want to grab navigation links, so we ignore links
    # that have a non-trailing slash / character or ?
    elsif(m!<A\s+HREF=\"([^?/\"]+/?)\">.*</A>!i) {
        my $filename = $1;
        my $filetype = ($filename =~ s|/$|| ? "d" : "f");
        return [$filename, $filetype, undef, undef, undef];
    }

    return ();
}


sub _guess_year {
    my $y = shift;

    # if the year is already four digit then we shouldn't do
    # anything to modify it.
    if ($y >= 1900) {
        # do nothing

    # TODO: for hysterical er historical reasons we assume 9x is in the
    # 1990s we should probably not do that, but I don't have any examples
    # where apache provides two digit dates so I am leaving this as-is
    # for now.  Possibly the right thing is to not handle two digit years.
    } elsif ($y >= 90) {
        $y = 1900+$y;
    }

    # TODO: likewise assuming 00-89 are 20xx is long term probably wrong.
    elsif ($y < 100) {
        $y = 2000+$y;
    }
    $y;
}


sub _monthabbrev_number {
    my $mon = shift;
    +{'Jan' => 1,
      'Feb' => 2,
      'Mar' => 3,
      'Apr' => 4,
      'May' => 5,
      'Jun' => 6,
      'Jul' => 7,
      'Aug' => 8,
      'Sep' => 9,
      'Oct' => 10,
      'Nov' => 11,
      'Dec' => 12,
     }->{$mon};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Listing - Parse directory listing

=head1 VERSION

version 6.15

=head1 SYNOPSIS

 use File::Listing qw(parse_dir);
 $ENV{LANG} = "C";  # dates in non-English locales not supported
 foreach my $file (parse_dir(`ls -l`)) {
     my ($name, $type, $size, $mtime, $mode) = @$file;
     next if $type ne 'f'; # plain file
     #...
 }
 
 # directory listing can also be read from a file
 open my $listing, "zcat ls-lR.gz|";
 $dir = parse_dir($listing, '+0000');

=head1 DESCRIPTION

This module exports a single function called C<parse_dir>, which can be
used to parse directory listings.

=head1 FUNCTIONS

=head2 parse_dir

 my $dir = parse_dir( $listing );
 my $dir = parse_dir( $listing, $time_zone );
 my $dir = parse_dir( $listing, $time_zone, $type );
 my $dir = parse_dir( $listing, $time_zone, $type, $error );
 my @files = parse_dir( $listing );
 my @files = parse_dir( $listing, $time_zone );
 my @files = parse_dir( $listing, $time_zone, $type );
 my @files = parse_dir( $listing, $time_zone, $type, $error );

The first parameter (C<$listing>) is the directory listing to parse.
It can be a scalar, a reference to an array of directory lines or a
glob representing a filehandle to read the directory listing from.

The second parameter (C<$time_zone>) is the time zone to use when
parsing time stamps in the listing. If this value is undefined,
then the local time zone is assumed.

The third parameter (C<$type>) is the type of listing to assume.
Currently supported formats are C<'unix'>, C<'apache'> and
C<'dosftp'>. The default value is C<'unix'>. Ideally, the listing
type should be determined automatically.

The fourth parameter (C<$error>) specifies how unparseable lines
should be treated. Values can be C<'ignore'>, C<'warn'> or a code reference.
Warn means that the perl warn() function will be called.  If a code
reference is passed, then this routine will be called and the return
value from it will be incorporated in the listing.  The default is
C<'ignore'>.

Only the first parameter is mandatory.

 # list context
 foreach my $file (parse_dir($listing)) {
     my($name, $type, $size, $mtime, $mode) = @$file;
 }
 
 # scalar context
 my $dir = parse_dir($listing);
 foreach my $file (@$dir) {
     my($name, $type, $size, $mtime, $mode) = @$file;
 }

The return value from parse_dir() is a list of directory entries.
In a scalar context the return value is a reference to the list.
The directory entries are represented by an array consisting of:

=over 4

=item name

The name of the file.

=item type

One of: C<f> file, C<d> directory, C<l> symlink, C<?> unknown.

=item size

The size of the file.

=item time

The number of seconds since January 1, 1970.

=item mode

Bitmask a la the mode returned by C<stat>.

=back

=head1 SEE ALSO

=over 4

=item L<File::Listing::Ftpcopy>

Provides the same interface but uses XS and the parser implementation from C<ftpcopy>.

=back

=head1 AUTHOR

Original author: Gisle Aas

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Adam Kennedy

Adam Sjogren

Alex Kapranoff

Alexey Tourbin

Andreas J. Koenig

Bill Mann

Bron Gondwana

DAVIDRW

Daniel Hedlund

David E. Wheeler

David Steinbrunner

Erik Esterer

FWILES

Father Chrysostomos

Gavin Peters

Graeme Thompson

Hans-H. Froehlich

Ian Kilgore

Jacob J

Mark Stosberg

Mike Schilli

Ondrej Hanak

Peter John Acklam

Peter Rabbitson

Robert Stone

Rolf Grossmann

Sean M. Burke

Simon Legner

Slaven Rezic

Spiros Denaxas

Steve Hay

Todd Lipcon

Tom Hukins

Tony Finch

Toru Yamaguchi

Ville Skyttä

Yuri Karaban

Zefram

amire80

jefflee

john9art

mschilli

murphy

phrstbrn

ruff

sasao

uid39246

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 1996-2020 by Gisle Aas.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
