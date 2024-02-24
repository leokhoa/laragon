package IO::InnerFile;

use strict;
use warnings;
use Symbol;

our $VERSION = '2.113';

sub new {
   my ($class, $fh, $start, $lg) = @_;
   $start = 0 if (!$start or ($start < 0));
   $lg    = 0 if (!$lg    or ($lg    < 0));

   ### Create the underlying "object":
   my $a = {
      FH 	=> 	$fh,
      CRPOS 	=> 	0,
      START	=>	$start,
      LG	=>	$lg,
   };

   ### Create a new filehandle tied to this object:
   $fh = gensym;
   tie(*$fh, $class, $a);
   return bless($fh, $class);
}

sub TIEHANDLE {
   my ($class, $data) = @_;
   return bless($data, $class);
}

sub DESTROY {
   my ($self) = @_;
   $self->close() if (ref($self) eq 'SCALAR');
}

sub set_length { tied(${$_[0]})->{LG} = $_[1]; }
sub get_length { tied(${$_[0]})->{LG}; }
sub add_length { tied(${$_[0]})->{LG} += $_[1]; }

sub set_start  { tied(${$_[0]})->{START} = $_[1]; }
sub get_start  { tied(${$_[0]})->{START}; }
sub set_end    { tied(${$_[0]})->{LG} =  $_[1] - tied(${$_[0]})->{START}; }
sub get_end    { tied(${$_[0]})->{LG} + tied(${$_[0]})->{START}; }

sub write    { shift->WRITE(@_) }
sub print    { shift->PRINT(@_) }
sub printf   { shift->PRINTF(@_) }
sub flush    { "0 but true"; }
sub fileno   { }
sub binmode  { 1; }
sub getc     { return GETC(tied(${$_[0]}) ); }
sub read     { return READ(     tied(${$_[0]}), @_[1,2,3] ); }
sub readline { return READLINE( tied(${$_[0]}) ); }

sub getline  { return READLINE( tied(${$_[0]}) ); }
sub close    { return CLOSE(tied(${$_[0]}) ); }

sub seek {
   my ($self, $ofs, $whence) = @_;
   $self = tied( $$self );

   $self->{CRPOS} = $ofs if ($whence == 0);
   $self->{CRPOS}+= $ofs if ($whence == 1);
   $self->{CRPOS} = $self->{LG} + $ofs if ($whence == 2);

   $self->{CRPOS} = 0 if ($self->{CRPOS} < 0);
   $self->{CRPOS} = $self->{LG} if ($self->{CRPOS} > $self->{LG});
   return 1;
}

sub tell {
    return tied(${$_[0]})->{CRPOS};
}

sub WRITE  {
    die "inner files can only open for reading\n";
}

sub PRINT  {
    die "inner files can only open for reading\n";
}

sub PRINTF {
    die "inner files can only open for reading\n";
}

sub GETC   {
    my ($self) = @_;
    return 0 if ($self->{CRPOS} >= $self->{LG});

    my $data;

    ### Save and seek...
    my $old_pos = $self->{FH}->tell;
    $self->{FH}->seek($self->{CRPOS}+$self->{START}, 0);

    ### ...read...
    my $lg = $self->{FH}->read($data, 1);
    $self->{CRPOS} += $lg;

    ### ...and restore:
    $self->{FH}->seek($old_pos, 0);

    $self->{LG} = $self->{CRPOS} unless ($lg);
    return ($lg ? $data : undef);
}

sub READ   {
    my ($self, $undefined, $lg, $ofs) = @_;
    $undefined = undef;

    return 0 if ($self->{CRPOS} >= $self->{LG});
    $lg = $self->{LG} - $self->{CRPOS} if ($self->{CRPOS} + $lg > $self->{LG});
    return 0 unless ($lg);

    ### Save and seek...
    my $old_pos = $self->{FH}->tell;
    $self->{FH}->seek($self->{CRPOS}+$self->{START}, 0);

    ### ...read...
    $lg = $self->{FH}->read($_[1], $lg, $_[3] );
    $self->{CRPOS} += $lg;

    ### ...and restore:
    $self->{FH}->seek($old_pos, 0);

    $self->{LG} = $self->{CRPOS} unless ($lg);
    return $lg;
}

sub READLINE {
    my ($self) = @_;
    return $self->_readline_helper() unless wantarray;
    my @arr;
    while(defined(my $line = $self->_readline_helper())) {
	    push(@arr, $line);
    }
    return @arr;
}

sub _readline_helper {
    my ($self) = @_;
    return undef if ($self->{CRPOS} >= $self->{LG});

    # Handle slurp mode (CPAN ticket #72710)
    if (! defined($/)) {
	    my $text;
	    $self->READ($text, $self->{LG} - $self->{CRPOS});
	    return $text;
    }

    ### Save and seek...
    my $old_pos = $self->{FH}->tell;
    $self->{FH}->seek($self->{CRPOS}+$self->{START}, 0);

    ### ...read...
    my $text = $self->{FH}->getline;

    ### ...and restore:
    $self->{FH}->seek($old_pos, 0);

    #### If we detected a new EOF ...
    unless (defined $text) {
       $self->{LG} = $self->{CRPOS};
       return undef;
    }

    my $lg=length($text);

    $lg = $self->{LG} - $self->{CRPOS} if ($self->{CRPOS} + $lg > $self->{LG});
    $self->{CRPOS} += $lg;

    return substr($text, 0,$lg);
}

sub CLOSE { %{$_[0]}=(); }



1;
__END__

__END__


=head1 NAME

IO::InnerFile - define a file inside another file

=head1 SYNOPSIS

    use strict;
    use warnings;
    use IO::InnerFile;

    # Read a subset of a file:
    my $fh = _some_file_handle;
    my $start = 10;
    my $length = 50;
    my $inner = IO::InnerFile->new($fh, $start, $length);
    while (my $line = <$inner>) {
        # ...
    }


=head1 DESCRIPTION

If you have a file handle that can C<seek> and C<tell>, then you
can open an L<IO::InnerFile> on a range of the underlying file.

=head1 CONSTRUCTORS

L<IO::InnerFile> implements the following constructors.

=head2 new

    my $inner = IO::InnerFile->new($fh);
    $inner = IO::InnerFile->new($fh, 10);
    $inner = IO::InnerFile->new($fh, 10, 50);

Create a new L<IO::InnerFile> opened on the given file handle.
The file handle supplied B<MUST> be able to both C<seek> and C<tell>.

The second and third parameters are start and length. Both are defaulted
to zero (C<0>). Negative values are silently coerced to zero.

=head1 METHODS

L<IO::InnerFile> implements the following methods.

=head2 add_length

    $inner->add_length(30);

Add to the virtual length of the inner file by the number given in bytes.

=head2 add_start

    $inner->add_start(30);

Add to the virtual position of the inner file by the number given in bytes.

=head2 binmode

    $inner->binmode();

This is a NOOP method just to satisfy the normal L<IO::File> interface.

=head2 close

=head2 fileno

    $inner->fileno();

This is a NOOP method just to satisfy the normal L<IO::File> interface.

=head2 flush

    $inner->flush();

This is a NOOP method just to satisfy the normal L<IO::File> interface.

=head2 get_end

    my $num_bytes = $inner->get_end();

Get the virtual end position of the inner file in bytes.

=head2 get_length

    my $num_bytes = $inner->get_length();

Get the virtual length of the inner file in bytes.

=head2 get_start

    my $num_bytes = $inner->get_start();

Get the virtual position of the inner file in bytes.

=head2 getc

=head2 getline

=head2 print LIST

=head2 printf

=head2 read

=head2 readline

=head2 seek

=head2 set_end

    $inner->set_end(30);

Set the virtual end of the inner file in bytes (this basically just alters the length).

=head2 set_length

    $inner->set_length(30);

Set the virtual length of the inner file in bytes.

=head2 set_start

    $inner->set_start(30);

Set the virtual start position of the inner file in bytes.

=head2 tell

=head2 write

=head1 AUTHOR

Eryq (F<eryq@zeegee.com>).
President, ZeeGee Software Inc (F<http://www.zeegee.com>).

=head1 CONTRIBUTORS

Dianne Skoll (F<dfs@roaringpenguin.com>).

=head1 COPYRIGHT & LICENSE

Copyright (c) 1997 Erik (Eryq) Dorfman, ZeeGee Software, Inc. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
