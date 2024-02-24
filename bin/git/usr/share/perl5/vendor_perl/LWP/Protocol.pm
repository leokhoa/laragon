package LWP::Protocol;

use parent 'LWP::MemberMixin';

our $VERSION = '6.72';

use strict;
use Carp ();
use HTTP::Status ();
use HTTP::Response ();
use Scalar::Util qw(openhandle);
use Try::Tiny qw(try catch);

my %ImplementedBy = (); # scheme => classname
my %ImplementorAlreadyTested;

sub new
{
    my($class, $scheme, $ua) = @_;

    my $self = bless {
	scheme => $scheme,
	ua => $ua,

	# historical/redundant
        max_size => $ua->{max_size},
    }, $class;

    $self;
}


sub create
{
    my($scheme, $ua) = @_;
    my $impclass = LWP::Protocol::implementor($scheme) or
	Carp::croak("Protocol scheme '$scheme' is not supported");

    # hand-off to scheme specific implementation sub-class
    my $protocol = $impclass->new($scheme, $ua);

    return $protocol;
}


sub implementor
{
    my($scheme, $impclass) = @_;

    if ($impclass) {
	$ImplementedBy{$scheme} = $impclass;
    }

    my $ic = $ImplementedBy{$scheme};
    # module does not exist
    return $ic if $ic || $ImplementorAlreadyTested{$scheme};

    return '' unless $scheme =~ /^([.+\-\w]+)$/;  # check valid URL schemes
    $scheme = $1; # untaint

    # scheme not yet known, look for a 'use'd implementation
    $ic = $scheme;
    $ic =~ tr/.+-/_/;  # make it a legal module name
    $ic = "LWP::Protocol::$ic";  # default location
    $ic = "LWP::Protocol::nntp" if $scheme eq 'news'; #XXX ugly hack
    no strict 'refs';
    # check we actually have one for the scheme:
    unless (@{"${ic}::ISA"}) {
        # try to autoload it
        try {
            (my $class = $ic) =~ s{::}{/}g;
            $class .= '.pm' unless $class =~ /\.pm$/;
            require $class;
        }
        catch {
            my $error = $_;
            if ($error =~ /Can't locate/) {
                $ic = '';
            }
            else {
                die "$error\n";
            }
        };
    }
    $ImplementedBy{$scheme} = $ic if $ic;
    $ImplementorAlreadyTested{$scheme} = 1;
    $ic;
}


sub request
{
    my($self, $request, $proxy, $arg, $size, $timeout) = @_;
    Carp::croak('LWP::Protocol::request() needs to be overridden in subclasses');
}


# legacy
sub timeout    { shift->_elem('timeout',    @_); }
sub max_size   { shift->_elem('max_size',   @_); }


sub collect
{
    my ($self, $arg, $response, $collector) = @_;
    my $content;
    my($ua, $max_size) = @{$self}{qw(ua max_size)};

    # This can't be moved to Try::Tiny due to the closures within causing
    # leaks on any version of Perl prior to 5.18.
    # https://perl5.git.perl.org/perl.git/commitdiff/a0d2bbd5c
    my $error = do { #catch
        local $@;
        local $\; # protect the print below from surprises
        eval { # try
            if (!defined($arg) || !$response->is_success) {
                $response->{default_add_content} = 1;
            }
            elsif (defined(openhandle($arg)) || !ref($arg) && length($arg)) {
                my $existing_fh = defined(openhandle($arg));
                my $mode = $existing_fh ? '>&=' : '>';
                open(my $fh, $mode, $arg) or die "Can't write to '$arg': $!";
                binmode($fh);
                push(@{$response->{handlers}{response_data}}, {
                    callback => sub {
                        print $fh $_[3] or die "Can't write to '$arg': $!";
                        1;
                    },
                });
                push(@{$response->{handlers}{response_done}}, {
                    callback => sub {
                        unless ($existing_fh) {
                            close($fh) or die "Can't write to '$arg': $!";
                        }
                        undef($fh);
                    },
                });
            }
            elsif (ref($arg) eq 'CODE') {
                push(@{$response->{handlers}{response_data}}, {
                    callback => sub {
                        &$arg($_[3], $_[0], $self);
                        1;
                    },
                });
            }
            else {
                die "Unexpected collect argument '$arg'";
            }

            $ua->run_handlers("response_header", $response);

            if (delete $response->{default_add_content}) {
                push(@{$response->{handlers}{response_data}}, {
                    callback => sub {
                        $_[0]->add_content($_[3]);
                        1;
                    },
                });
            }


            my $content_size = 0;
            my $length = $response->content_length;
            my %skip_h;

            while ($content = &$collector, length $$content) {
                for my $h ($ua->handlers("response_data", $response)) {
                    next if $skip_h{$h};
                    unless ($h->{callback}->($response, $ua, $h, $$content)) {
                        # XXX remove from $response->{handlers}{response_data} if present
                        $skip_h{$h}++;
                    }
                }
                $content_size += length($$content);
                $ua->progress(($length ? ($content_size / $length) : "tick"), $response);
                if (defined($max_size) && $content_size > $max_size) {
                    $response->push_header("Client-Aborted", "max_size");
                    last;
                }
            }
            1;
        };
        $@;
    };

    if ($error) {
        chomp($error);
        $response->push_header('X-Died' => $error);
        $response->push_header("Client-Aborted", "die");
    };
    delete $response->{handlers}{response_data};
    delete $response->{handlers} unless %{$response->{handlers}};
    return $response;
}


sub collect_once
{
    my($self, $arg, $response) = @_;
    my $content = \ $_[3];
    my $first = 1;
    $self->collect($arg, $response, sub {
	return $content if $first--;
	return \ "";
    });
}

1;


__END__

=pod

=head1 NAME

LWP::Protocol - Base class for LWP protocols

=head1 SYNOPSIS

 package LWP::Protocol::foo;
 use parent qw(LWP::Protocol);

=head1 DESCRIPTION

This class is used as the base class for all protocol implementations
supported by the LWP library.

When creating an instance of this class using
C<LWP::Protocol::create($url)>, and you get an initialized subclass
appropriate for that access method. In other words, the
L<LWP::Protocol/create> function calls the constructor for one of its
subclasses.

All derived C<LWP::Protocol> classes need to override the C<request()>
method which is used to service a request. The overridden method can
make use of the C<collect()> method to collect together chunks of data
as it is received.

=head1 METHODS

The following methods and functions are provided:

=head2 new

    my $prot = LWP::Protocol->new();

The LWP::Protocol constructor is inherited by subclasses. As this is a
virtual base class this method should B<not> be called directly.

=head2 create

    my $prot = LWP::Protocol::create($scheme)

Create an object of the class implementing the protocol to handle the
given scheme. This is a function, not a method. It is more an object
factory than a constructor. This is the function user agents should
use to access protocols.

=head2 implementor

    my $class = LWP::Protocol::implementor($scheme, [$class])

Get and/or set implementor class for a scheme.  Returns C<''> if the
specified scheme is not supported.

=head2 request

    $response = $protocol->request($request, $proxy, undef);
    $response = $protocol->request($request, $proxy, '/tmp/sss');
    $response = $protocol->request($request, $proxy, \&callback, 1024);
    $response = $protocol->request($request, $proxy, $fh);

Dispatches a request over the protocol, and returns a response
object. This method needs to be overridden in subclasses.  Refer to
L<LWP::UserAgent> for description of the arguments.

=head2 collect

    my $res = $prot->collect(undef, $response, $collector); # stored in $response
    my $res = $prot->collect($filename, $response, $collector);
    my $res = $prot->collect(sub { ... }, $response, $collector);

Collect the content of a request, and process it appropriately into a scalar,
file, or by calling a callback. If the first parameter is undefined, then the
content is stored within the C<$response>. If it's a simple scalar, then it's
interpreted as a file name and the content is written to this file.  If it's a
code reference, then content is passed to this routine.
If it is a filehandle, or similar, such as a L<File::Temp> object,
content will be written to it.

The collector is a routine that will be called and which is
responsible for returning pieces (as ref to scalar) of the content to
process.  The C<$collector> signals C<EOF> by returning a reference to an
empty string.

The return value is the L<HTTP::Response> object reference.

B<Note:> We will only use the callback or file argument if
C<< $response->is_success() >>.  This avoids sending content data for
redirects and authentication responses to the callback which would be
confusing.

=head2 collect_once

    $prot->collect_once($arg, $response, $content)

Can be called when the whole response content is available as content. This
will invoke L<LWP::Protocol/collect> with a collector callback that
returns a reference to C<$content> the first time and an empty string the
next.

=head1 SEE ALSO

Inspect the F<LWP/Protocol/file.pm> and F<LWP/Protocol/http.pm> files
for examples of usage.

=head1 COPYRIGHT

Copyright 1995-2001 Gisle Aas.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
