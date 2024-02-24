use strict;
use warnings;

package SVN::Core;
use SVN::Base qw(Core svn_ VERSION);
# Some build tool hates VERSION assign across two lines.
$SVN::Core::VERSION = "$SVN::Core::VER_MAJOR.$SVN::Core::VER_MINOR.$SVN::Core::VER_MICRO";

=head1 NAME

SVN::Core - Core module of the subversion perl bindings

=head1 SYNOPSIS

    use SVN::Core; # does apr_initialize and cleanup for you

    # create a root pool and set it as default pool for later use
    my $pool = SVN::Pool->new_default;

    sub something {
        # create a subpool of the current default pool
        my $pool = SVN::Pool->new_default_sub;
        # some svn operations...

        # $pool gets destroyed and the previous default pool
        # is restored when $pool's lexical scope ends
    }

    # svn_stream_t as native perl io handle
    my $stream = $txn->root->apply_text('trunk/filea', undef);
    print $stream $text;
    close $stream;

    # native perl io handle as svn_stream_t
    SVN::Repos::dump_fs($repos, \*STDOUT, \*STDERR,
                        0, $repos->fs->youngest_rev, 0);

=head1 DESCRIPTION

SVN::Core implements higher level functions of fundamental subversion
functions.

=head1 FUNCTIONS

=over 4

=cut

BEGIN {
    SVN::_Core::apr_initialize();
}

my $gpool = SVN::Pool->new_default;
sub gpool { $gpool } # holding the reference to gpool
SVN::Core::utf_initialize($gpool);

END {
    SVN::_Core::apr_terminate();
}

=item SVN::Core::auth_open([auth provider array]);

Takes a reference to an array of authentication providers
and returns an auth_baton.  If you use prompt providers
you can not use this function, but need to use the
auth_open_helper.

=item SVN::Core::auth_open_helper([auth provider array]);

Prompt providers return two values instead of one.  The
2nd parameter is a reference to whatever was passed into
them as the callback.  auth_open_helper splits up these
arguments, passing the provider objects into auth_open
which gives it an auth_baton and putting the other
ones in an array.  The first return value of this
function is the auth_baton, the second is a reference
to an array containing the references to the callbacks.

These callback arrays should be stored in the object
the auth_baton is attached to.

=back

=cut

sub auth_open_helper {
    my $args = shift;
    my (@auth_providers,@auth_callbacks);

    foreach my $arg (@{$args}) {
        if (ref($arg) eq '_p_svn_auth_provider_object_t') {
            push @auth_providers, $arg;
        } else {
            push @auth_callbacks, $arg;
        }
    }
    my $auth_baton = SVN::Core::auth_open(\@auth_providers);
    return ($auth_baton,\@auth_callbacks);
}

# import the INVALID and IGNORED constants
our $INVALID_REVNUM = $SVN::_Core::SWIG_SVN_INVALID_REVNUM;
our $IGNORED_REVNUM = $SVN::_Core::SWIG_SVN_IGNORED_REVNUM;

package _p_svn_stream_t;
use SVN::Base qw(Core svn_stream_);

package SVN::Stream;
use IO::Handle;
our @ISA = qw(IO::Handle);

=head1 OTHER OBJECTS

=head2 svn_stream_t - SVN::Stream

You can use native perl io handles (including io globs) as
svn_stream_t in subversion functions. Returned svn_stream_t are also
translated into perl io handles, so you could access them with regular
print, read, etc.

Note that some functions take a stream to read from or write to, but do not
close the stream while still holding the reference to the io handle.
In this case the handle won't be destroyed properly.
You should always set up the correct default pool before calling
such functions.

=cut

use Symbol ();

sub new
{
    my $class = shift;
    my $self = bless Symbol::gensym(), ref($class) || $class;
    tie *$self, $self;
    *$self->{svn_stream} = shift;
    $self;
}

sub svn_stream {
    my $self = shift;
    *$self->{svn_stream};
}

sub TIEHANDLE
{
    return $_[0] if ref($_[0]);
    my $class = shift;
    my $self = bless Symbol::gensym(), $class;
    *$self->{svn_stream} = shift;
    $self;
}

sub CLOSE
{
    my $self = shift;
    *$self->{svn_stream}->close
        if *$self->{svn_stream};
    undef *$self->{svn_stream};
}

sub GETC
{
    my $self = shift;
    my $buf;
    return $buf if $self->read($buf, 1);
    return undef;
}

sub print
{
    my $self = shift;
    $self->WRITE($_[0], length($_[0]));
}

sub PRINT
{
    my $self = shift;
    if (defined $\) {
        if (defined $,) {
            $self->print(join($,, @_).$\);
        } else {
            $self->print(join("",@_).$\);
        }
    } else {
        if (defined $,) {
            $self->print(join($,, @_));
        } else {
            $self->print(join("",@_));
        }
    }
}

sub PRINTF
{
    my $self = shift;
    my $fmt = shift;
    $self->print(sprintf($fmt, @_));
}

sub getline
{
    my $self = shift;
    *$self->{pool} ||= SVN::Core::pool_create(undef);
    my ($buf, $eof) = *$self->{svn_stream}->readline($/, *$self->{pool});
    return undef if $eof && !length($buf);
    return $eof ? $buf : $buf.$/;
}

sub getlines
{
    die "getlines() called in scalar context\n" unless wantarray;
    my $self = shift;
    my($line, @lines);
    push @lines, $line while defined($line = $self->getline);
    return @lines;
}

sub READLINE
{
    my $self = shift;
    unless (defined $/) {
        my $buf = '';
        while (length( my $chunk = *$self->{svn_stream}->read
               ($SVN::Core::STREAM_CHUNK_SIZE)) ) {
            $buf .= $chunk;
        }
        return $buf;
    }
    elsif (ref $/) {
        my $buf = *$self->{svn_stream}->read(${$/});
        return length($buf) ? $buf : undef;
    }
    return wantarray ? $self->getlines : $self->getline;
}

sub READ {
    my $self = shift;
    my $len = $_[1];
    if (@_ > 2) { # read offset
        substr($_[0],$_[2]) = *$self->{svn_stream}->read($len);
    } else {
        $_[0] = *$self->{svn_stream}->read($len);
    }
    return $len;
}

sub WRITE {
    my $self = shift;
    my $slen = length($_[0]);
    my $len = $slen;
    my $off = 0;

    if (@_ > 1) {
        $len = $_[1] if $_[1] < $len;
        if (@_ > 2) {
            $off = $_[2] || 0;
            die "Offset outside string" if $off > $slen;
            if ($off < 0) {
                $off += $slen;
                die "Offset outside string" if $off < 0;
            }
            my $rem = $slen - $off;
            $len = $rem if $rem < $len;
        }
        *$self->{svn_stream}->write(substr($_[0], $off, $len));
    }
    return $len;
}

*close = \&CLOSE;

sub FILENO {
    return undef;   # XXX perlfunc says this means the file is closed
}

sub DESTROY {
    my $self = shift;
    $self->close;
}

package _p_apr_pool_t;

my %WRAPPED;

sub default {
    my ($pool) = @_;
    my $pobj = SVN::Pool->_wrap($$pool);
    $WRAPPED{$pool} = $pobj;
    $pobj->default;
}

sub DESTROY {
    my ($pool) = @_;
    delete $WRAPPED{$pool};
}

package SVN::Pool;
use SVN::Base qw(Core svn_pool_);

=head2 svn_pool_t - SVN::Pool

The perl bindings significantly simplify the usage of pools, while
still being manually adjustable.

For functions requiring a pool as the last argument (which are, almost all
of the subversion functions), the pool argument is optional. The default pool
is used if it is omitted. When C<SVN::Core> is loaded, it creates a
new default pool, which is also available from C<SVN::Core-E<gt>gpool>.

For callback functions providing a pool to your subroutine, you could
also use $pool-E<gt>default to make it the default pool in the scope.

=head3 Methods

=over 4

=item new([$parent])

Create a new pool. The pool is a root pool if $parent is not supplied.

=item new_default([$parent])

Create a new pool. The pool is a root pool if $parent is not supplied.
Set the new pool as default pool.

=item new_default_sub

Create a new subpool of the current default pool, and set the
resulting pool as new default pool.

=item clear

Clear the pool.

=item DESTROY

Destroy the pool. If the pool was the default pool, restore the
previous default pool. This is normally called
automatically when the SVN::Pool object is no longer used and
destroyed by the perl garbage collector.

=back

=cut

{
    # block is here to restrict no strict refs to this block
    no strict 'refs';
    *{"apr_pool_$_"} = *{"SVN::_Core::apr_pool_$_"}
        for qw/clear destroy/;
}

my @POOLSTACK;

sub new {
    my ($class, $parent) = @_;
    $parent = $$parent if ref($parent) eq 'SVN::Pool';
    my $self = bless \create($parent), $class;
    return $self;
}

sub new_default_sub {
    my $parent = ref($_[0]) ? ${+shift} : $SVN::_Core::current_pool;
    my $self = SVN::Pool->new_default($parent);
    return $self;
}

sub new_default {
    my $self = new(@_);
    $self->default;
    return $self;
}

sub default {
    my $self = shift;
    push @POOLSTACK, $SVN::_Core::current_pool
        unless $$SVN::_Core::current_pool == 0;
    $SVN::_Core::current_pool = $$self;
}

sub clear {
    my $self = shift;
    apr_pool_clear($$self);
}

my $globaldestroy;

END {
    $globaldestroy = 1;
}

my %WRAPPOOL;

# Create a cloned _p_apr_pool_t pointing to the same apr_pool_t
# but on different address. this allows pools that are from C
# to have proper lifetime.
sub _wrap {
    my ($class, $rawpool) = @_;
    my $pool = \$rawpool;
    bless $pool, '_p_apr_pool_t';
    my $npool = \$pool;
    bless $npool, $class;
    $WRAPPOOL{$npool} = 1;
    $npool;
}

use Scalar::Util 'reftype';

sub DESTROY {
    return if $globaldestroy;
    my $self = shift;
    # for some reason, REF becomes SCALAR in perl -c or after apr_terminate
    return if reftype($self) eq 'SCALAR';
    if ($$self eq $SVN::_Core::current_pool) {
        $SVN::_Core::current_pool = pop @POOLSTACK;
    }
    if (exists $WRAPPOOL{$self}) {
        delete $WRAPPOOL{$self};
    }
    else {
        apr_pool_destroy($$self)
    }
}

package _p_svn_error_t;
use SVN::Base qw(Core svn_error_t_);

sub strerror {
    return SVN::Error::strerror($_[$[]->apr_err());
}

sub handle_error {
    return SVN::Error::handle_error(@_);
}

sub expanded_message {
    return SVN::Error::expanded_message(@_);
}

sub handle_warning {
    # need to swap parameter order.
    return SVN::Error::handle_warning($_[$[+1],$_[$[]);
}

foreach my $function (qw(compose clear quick_wrap)) {
    no strict 'refs';
    my $real_function = \&{"SVN::_Core::svn_error_$function"};
    *{"_p_svn_error_t::$function"} = sub {
        return $real_function->(@_);
    }
}

package SVN::Error;
use SVN::Base qw(Core svn_error_);
use SVN::Base qw(Core SVN_ERR_);
use Carp;
our @CARP_NOT = qw(SVN::Base SVN::Client SVN::Core SVN::Delta
                   SVN::Delta::Editor SVN::Error SVN::Fs SVN::Node
                   SVN::Pool SVN::Ra SVN::Ra::Callbacks SVN::Ra::Reporter
                   SVN::Repos SVN::Stream SVN::TxDelta SVN::Wc);

=head2 svn_error_t - SVN::Error

By default the perl bindings handle exceptions for you.  The default handler
automatically croaks with an appropriate error message.  This is likely
sufficient for simple scripts, but more complex usage may demand handling of
errors.

You can override the default exception handler by changing the
$SVN::Error::handler variable.  This variable holds a reference to a perl sub
that should be called whenever an error is returned by a svn function.  This
sub will be passed a svn_error_t object.   Its return value is ignored.

If you set the $SVN::Error::handler to undef then each call will return an
svn_error_t object as its first return in the case of an error, followed by the
normal return values.  If there is no error then a svn_error_t will not be
returned and only the normal return values will be returned.  When using this
mode you should be careful only to call functions in array context.  For
example: my ($ci) = $ctx-E<gt>mkdir('http://svn/foo');  In this case $ci will
be an svn_error_t object if an error occurs and a svn_client_commit_info object
otherwise.  If you leave the parenthesis off around $ci (scalar context) it
will be the commit_info object, which in the case of an error will be undef.

If you plan on using explicit exception handling, understanding the exception
handling system the C API uses is helpful.  You can find information on it in
the HACKING file and the API documentation.  Looking at the implementation of
SVN::Error::croak_on_error and SVN::Error::expanded_message may be helpful as
well.

=over 4

=item $svn_error_t-E<gt>apr_err()

APR error value, possibly SVN_ custom error.

=item $svn_error_t-E<gt>message()

Details from producer of error.

=item $svn_error_t-E<gt>child()

svn_error_t object of the error that's wrapped.

=item $svn_error_t-E<gt>pool()

The pool holding this error and any child errors it wraps.

=item $svn_error_t-E<gt>file()

Source file where the error originated.

=item $svn_error_t-E<gt>line()

Source line where the error originated.

=item SVN::Error::strerror($apr_status_t)

Returns the english description of the status code.

=item $svn_error_t-E<gt>strerror()

Returns the english description of the apr_err status code set on the
$svn_error_t.  This is short for:
SVN::Error::strerror($svn_error_t-E<gt>apr_err());

=item SVN::Error::create($apr_err, $child, $message);

Returns a new svn_error_t object with the error status specified in $apr_err,
the child as $child, and error message of $message.

=item SVN::Error::quick_wrap($child, $new_msg); or $child-E<gt>quick_wrap($new_msg);

A quick n' easy way to create a wrappered exception with your own message
before throwing it up the stack.

$child is the svn_error_t object you want to wrap and $new_msg is the new error
string you want to set.

=item SVN::Error::compose($chain, $new_error); or $chain-E<gt>compose($new_error);

Add new_err to the end of $chain's chain of errors.

The $new_err chain will be copied into $chain's pool and destroyed, so $new_err
itself becomes invalid after this function.

=item SVN::Error::clear($svn_error_t); or $svn_error_t-E<gt>clear();

Free the memory used by $svn_error_t, as well as all ancestors and descendants
of $svn_error_t.

You must call this on every svn_error_t object you get or you will leak memory.

=cut

# Permit users to determine if they want automatic croaking or not.
our $handler = \&croak_on_error;

# Import functions that don't follow the normal naming scheme.
foreach my $function (qw(handle_error handle_warning strerror)) {
    no strict 'refs';
    my $real_function = \&{"SVN::_Core::svn_$function"};
    *{"SVN::Error::$function"} = sub {
        return $real_function->(@_);
    }
}

=item SVN::Error::expanded_message($svn_error_t) or $svn_error_t-E<gt>expanded_message()

Returns the error message by tracing through the svn_error_t object and its
children and concatenating the error messages.  This is how the internal
exception handlers get their error messages.

=cut

sub expanded_message {
    my $svn_error = shift;
    unless (is_error($svn_error)) {
        return undef;
    }

    my $error_message = $svn_error->strerror();
    while ($svn_error) {
        my $msg = $svn_error->message();
        $error_message .= ": $msg" if $msg;
        $svn_error = $svn_error->child();
    }
    return $error_message;
}


=item SVN::Error::is_error($value)

Returns true if value is of type svn_error.  Returns false if value is
anything else or undefined.  This is useful for seeing if a call has returned
an error.

=cut

sub is_error {
     return (ref($_[$[]) eq '_p_svn_error_t');
}

=item SVN::Error::croak_on_error

Default error handler.  It takes an svn_error_t and extracts the error messages
from it and croaks with those messages.

It can be used in two ways.  The first is detailed above as setting it as the
automatic exception handler via setting $SVN::Error::handler.

The second is if you have $SVN::Error::handler set to undef as a wrapper for
calls you want to croak on when there is an error, but you don't want to write
an explicit error handler. For example:

my $rev = SVN::Error::croak_on_error($ctx-E<gt>checkout($url,$path,'HEAD',1));

If there is no error then croak_on_error will return the arguments passed to it
unchanged.

=cut

sub croak_on_error {
    unless (is_error($_[$[])) {
      return @_;
    }
    my $svn_error = shift;

    my $error_message = $svn_error->expanded_message();

    $svn_error->clear();

    croak($error_message);
}

=item SVN::Error::confess_on_error

The same as croak_on_error except it will give a more detailed stack backtrace,
including internal calls within the implementation of the perl bindings.
This is useful when you are doing development work on the bindings themselves.

=cut

sub confess_on_error {
    unless (is_error($_[$[])) {
        return @_;
    }
    my $svn_error = shift;

    my $error_message = $svn_error->expanded_message();

    $svn_error->clear();

    confess($error_message);
}

=item SVN::Error::ignore_error

This is useful for wrapping around calls which you wish to ignore any potential
error.  It checks to see if the first parameter is an error and if it is it
clears it.  It then returns all the other parameters.

=back

=cut

sub ignore_error {
    if (is_error($_[$[])) {
        my $svn_error = shift;
        $svn_error->clear();
    }

    return @_;
}

package _p_svn_log_changed_path_t;
use SVN::Base qw(Core svn_log_changed_path_t_);

=head2 svn_log_changed_path_t

=over 4

=item $lcp-E<gt>action()

'A'dd, 'D'elete, 'R'eplace, 'M'odify

=item $lcp-E<gt>copyfrom_path()

Source path of copy, or C<undef> if there isn't any previous revision
history.

=item $lcp-E<gt>copyfrom_rev()

Source revision of copy, or C<$SVN::Core::INVALID_REVNUM> if there is
no previous history.

=back

=cut

package _p_svn_log_changed_path2_t;
use SVN::Base qw(Core svn_log_changed_path2_t_);

=head2 svn_log_changed_path2_t

An object to represent a path that changed for a log entry.

=over 4

=item $lcp-E<gt>action()

'A'dd, 'D'elete, 'R'eplace, 'M'odify

=item $lcp-E<gt>copyfrom_path()

Source path of copy, or C<undef> if there isn't any previous revision
history.

=item $lcp-E<gt>copyfrom_rev()

Source revision of copy, or C<$SVN::Core::INVALID_REVNUM> if there is
no previous history.

=item $lcp-E<gt>node_kind()

The type of the node, a C<$SVN::Node> enum; may be C<$SVN::Node::unknown>.

=item $lcp-E<gt>text_modified()

Is the text modified, a C<SVN::Tristate> enum, 
may be C<$SVN::Tristate::unknown>.

=item $lcp-E<gt>props_modified()

Are properties modified, a C<SVN::Tristate> enum,
may be C<$SVN::Tristate::unknown>.

=back

=cut

package SVN::Node;
use SVN::Base qw(Core svn_node_);

=head2 svn_node_kind_t - SVN::Node

An enum of the following constants:

$SVN::Node::none, $SVN::Node::file,
$SVN::Node::dir, $SVN::Node::unknown.

=cut

package SVN::Tristate;
use SVN::Base qw(Core svn_tristate_);

=head2 svn_tristate_t - SVN::Tristate

An enum of the following constants:

$SVN::Tristate::true, $SVN::Tristate::false, $SVN::Tristate::unknown

Note that these true/false values have nothing to do with Perl's concept 
of truth. In fact, each constant would evaluate to true in a boolean context.

=cut

package SVN::Depth;
use SVN::Base qw(Core svn_depth_);

=head2 svn_depth_t - SVN::Depth

An enum of the following constants:

=over 4

=item $SVN::Depth::unknown

Depth undetermined or ignored.  In some contexts, this means the client should
choose an appropriate default depth.  The server will generally treat it as
$SVN::Depth::infinity.

=item $SVN::Depth::exclude

Exclude (i.e., don't descend into) directory D.

Note: In Subversion 1.5, $SVN::Depth::exclude is B<not> supported anyhwere in
the client-side (Wc/Client/etc) code; it is only supported as an argument to
set_path functions in the Ra and Repos reporters.  (This will enable future
versions of Subversion to run updates, etc, against 1.5 servers with proper
$SVN::Depth::exclude behavior, once we get a chance to implement client side
support for $SVN::Depth::exclude).

=item $SVN::Depth::empty

Just the named directory D, no entries.

Updates will not pull in any files or subdirectories not already present.

=item $SVN::Depth::files

D + its files children, but not subdirs.

Updates will pull in any files not already present, but not subdirectories.

=item $SVN::Depth::immediates

D + immediate children (D and its entries).

Updates will pull in any files or subdirectories not already present; those
subdirectories' this_dir entries will have depth-empty.

=item $SVN::Depth::infinity

D + all descendants (full recursion from D).

Updates will pull in any files or subdirectories not already present; those
subdirectories' this_dir entries will have depth-infinity.  Equivalent to the
pre 1.5 default update behavior.

=back

=cut

package _p_svn_opt_revision_t;
use SVN::Base qw(Core svn_opt_revision_t_);

=head2 svn_opt_revision_t

A revision, specified in one of C<SVN::Core::opt_revision_*> ways.

=over 4

=item $rev-E<gt>kind()

An enum denoting how the revision C<$rev> was specified.  One of 
C<$SVN::Core::opt_revision_unspecified>,
C<$SVN::Core::opt_revision_number>,
C<$SVN::Core::opt_revision_date>,
C<$SVN::Core::opt_revision_committed>,
C<$SVN::Core::opt_revision_previous>,
C<$SVN::Core::opt_revision_base>,
C<$SVN::Core::opt_revision_working>
or C<$SVN::Core::opt_revision_head>.

=item $rev-E<gt>value()

Extra data about the revision. Only relevant if C<$rev-E<gt>kind> is
C<$SVN::Core::opt_revision_number> (where it contains the revision number)
or C<$SVN::Core::opt_revision_date> (where it contains a date).

=back

=cut

package _p_svn_opt_revision_value_t;
use SVN::Base qw(Core svn_opt_revision_value_t_);

package _p_svn_opt_revision_range_t;
use SVN::Base qw(Core svn_opt_revision_range_t_);

=head2 svn_opt_revision_range_t

An object representing a range of revisions.

=over 4

=item $range-E<gt>start()

The first revision in the range, a C<_p_svn_opt_revision_t> object.

=item $range-E<gt>end()

The last revision in the range, a C<_p_svn_opt_revision_t> object.

=back

=cut

package _p_svn_config_t;
use SVN::Base qw(Core svn_config_);

=head2 svn_config_t

Opaque object describing a set of configuration options.

=cut

package _p_svn_dirent_t;
use SVN::Base qw(Core svn_dirent_t_);

=head2 svn_dirent_t

=over 4

=item $dirent-E<gt>kind()

Node kind.  A number which matches one of these constants:
$SVN::Node::none, $SVN::Node::file,
$SVN::Node::dir, $SVN::Node::unknown.

=item $dirent-E<gt>size()

Length of file text, or 0 for directories.

=item $dirent-E<gt>has_props()

Does the node have properties?

=item $dirent-E<gt>created_rev()

Last revision in which this node changed.

=item $dirent-E<gt>time()

Time of created_rev (mod-time).

=item $dirent-E<gt>last_author()

Author of created rev.

=back

=cut

package _p_svn_commit_info_t;
use SVN::Base qw(Core svn_commit_info_t_);

=head2 svn_commit_info_t

=over 4

=item $commit-E<gt>revision()

Just committed revision.

=item $commit-E<gt>date()

Server-side date of the commit.

=item $commit-E<gt>author()

Author of the commit.

=item $commit-E<gt>post_commit_err()

Error message from the post-commit hook, or undef.

=item $commit-E<gt>repos_root()

Repository root, may be C<undef> if unknown.

=back

=cut

package _p_svn_log_entry_t;
use SVN::Base qw(Core svn_log_entry_t_);

=head2 svn_log_entry_t

=over 4

=item $entry-E<gt>revision()

The revision of the commit.

=item $entry-E<gt>revprops()

A reference to a hash of requested revision properties, 
which may be C<undef> if it would contain no revprops. 

=item $entry-E<gt>has_children()

Whether or not this message has children.

=item $entry-E<gt>changed_paths2()

A reference to hash containing as keys every path committed in 
C<$entry-E<gt>revision()>; the values are C<_p_svn_log_changed_path2_t>
objects.

=item $entry-E<gt>non_inheritable()

Whether C<$entry-E<gt>revision()> should be interpreted as non-inheritable 
in the same sense of C<_p_svn_merge_range_t>.

=item $entry-E<gt>subtractive_merge()

Whether C<$entry-E<gt>revision()> is a merged revision resulting 
from a reverse merge.

=back

=cut

package _p_svn_auth_cred_simple_t;
use SVN::Base qw(Core svn_auth_cred_simple_t_);

=head2 svn_auth_cred_simple_t

=over 4

=item $simple-E<gt>username()

Username.

=item $simple-E<gt>password()

Password.

=item $simple-E<gt>may_save()

Indicates if the credentials may be saved (to disk).

=back

=cut

package _p_svn_auth_cred_username_t;
use SVN::Base qw(Core svn_auth_cred_username_t_);

=head2 svn_auth_cred_username_t

=over 4

=item $username-E<gt>username()

Username.

=item $username-E<gt>may_save()

Indicates if the credentials may be saved (to disk).

=back

=cut

package _p_svn_auth_cred_ssl_server_trust_t;
use SVN::Base qw(Core svn_auth_cred_ssl_server_trust_t_);

=head2 svn_auth_cred_ssl_server_trust_t

=over 4

=item $strust-E<gt>may_save()

Indicates if the credentials may be saved (to disk).

=item $strust-E<gt>accepted_failures()

Bit mask of the accepted failures.

=back

=cut

package _p_svn_auth_ssl_server_cert_info_t;
use SVN::Base qw(Core svn_auth_ssl_server_cert_info_t_);

=head2 svn_auth_ssl_server_cert_info_t

=over 4

=item $scert-E<gt>hostname()

Primary CN.

=item $scert-E<gt>fingerprint()

ASCII fingerprint.

=item $scert-E<gt>valid_from()

ASCII date from which the certificate is valid.

=item $scert-E<gt>valid_until()

ASCII date until which the certificate is valid.

=item $scert-E<gt>issuer_dname()

DN of the certificate issuer.

=item $scert-E<gt>ascii_cert()

Base-64 encoded DER certificate representation.

=back

=cut

package _p_svn_auth_cred_ssl_client_cert_t;
use SVN::Base qw(Core svn_auth_cred_ssl_client_cert_t_);

=head2 svn_auth_cred_ssl_client_cert_t

=over 4

=item $ccert-E<gt>cert_file()

Full paths to the certificate file.

=item $ccert-E<gt>may_save()

Indicates if the credentials may be saved (to disk).

=back

=cut

package _p_svn_auth_cred_ssl_client_cert_pw_t;
use SVN::Base qw(Core svn_auth_cred_ssl_client_cert_pw_t_);

=head2 svn_auth_cred_ssl_client_cert_pw_t

=over 4

=item $ccertpw-E<gt>password()

Certificate password.

=item $ccertpw-E<gt>may_save()

Indicates if the credentials may be saved (to disk).

=back

=cut

=head1 CONSTANTS

=head2 SVN::Auth::SSL

=over 4

=item $SVN::Auth::SSL::NOTYETVALID

Certificate is not yet valid.

=item $SVN::Auth::SSL::EXPIRED

Certificate has expired.

=item $SVN::Auth::SSL::CNMISMATCH

Certificate's CN (hostname) does not match the remote hostname.

=item $SVN::Auth::SSL::UNKNOWNCA

Certificate authority is unknown (i.e. not trusted).

=item $SVN::Auth::SSL::OTHER

Other failure. This can happen if some unknown error condition occurs.

=back

=cut

package SVN::Auth::SSL;
use SVN::Base qw(Core SVN_AUTH_SSL_);

package _p_svn_lock_t;
use SVN::Base qw(Core svn_lock_t_);

=head2 _p_svn_lock_t

Objects of this class contain information about locks placed on files
in a repository.  It has the following accessor methods:

=over

=item path

The full path to the file which is locked, starting with a forward slash (C</>).

=item token

A string containing the lock token, which is a unique URI.

=item owner

The username of whoever owns the lock.

=item comment

A comment associated with the lock, or undef if there isn't one.

=item is_dav_comment

True if the comment was made by a generic DAV client.

=item creation_date

Time at which the lock was created, as the number of microseconds since
00:00:00 S<January 1>, 1970 UTC.  Divide it by 1_000_000 to get a Unix
time_t value.

=item expiration_date

When the lock will expire.  Has the value '0' if the lock will never expire.

=back

=cut

package SVN::MD5;
use overload
    '""' => sub { SVN::Core::md5_digest_to_cstring(${$_[0]})};

sub new {
    my ($class, $digest) = @_;
    bless \$digest, $class;
}

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 COPYRIGHT

    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.

=cut

1;
