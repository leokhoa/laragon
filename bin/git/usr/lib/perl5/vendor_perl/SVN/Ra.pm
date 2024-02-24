use strict;
use warnings;

package SVN::Ra;
use SVN::Base qw(Ra);
use File::Temp;

=head1 NAME

SVN::Ra - Subversion remote access functions

=head1 SYNOPSIS

    use SVN::Core;
    use SVN::Ra;

    my $ra = SVN::Ra->new('file:///tmp/svntest');
    print $ra->get_latest_revnum;

=head1 DESCRIPTION

SVN::Ra wraps the object-oriented C<svn_ra_plugin_t> functions,
providing access to a Subversion repository though a URL, using
whichever repository access module is appropriate.

=head1 SVN::Ra

=head2 SVN::Ra-E<gt>new(...)

The constructor creates an RA object and calls C<open> for it.  Its parameters
are either a hash of options or a single value containing the URL of the
repository.  Valid options are:

=over

=item url

The URL of the repository.

=item auth

An C<auth_baton> could be given to the SVN::RA object.  Defaults to an
C<auth_provider> with a C<username_provider>.  See L<SVN::Client> for how to
create C<auth_baton>.

=item pool

The pool for the RA session to use.  Member functions will also be
called with this pool.  Defaults to a newly created root pool.

=item config

The config hash that could be obtained by calling
C<SVN::Core::config_get_config(undef)>.

=item callback

The C<ra_callback> namespace to use.  Defaults to SVN::Ra::Callbacks.

=back

The following examples will both do the same thing, with all the optional
arguments taking their defaults:

    my $ra = SVN::Ra->new('file:///tmp/repos');
    my $ra = SVN::Ra->new(url => 'file:///tmp/repos');

=head2 METHODS

Please consult the svn_ra.h section in the Subversion API. Member
functions of C<svn_ra_plugin_t> can be called as methods of SVN::Ra
objects, with the C<session_baton> and C<pool> arguments omitted.

=over

=item $ra-E<gt>change_rev_prop($revnum, $name, $value)

Sets the revision (unversioned) property C<$name> to C<$value> on
revision C<$revnum>, or removes the property if C<$value> is undef.

    $ra->change_rev_prop(123, 'svn:log', 'New log message.');

Of course this will only work if there is a C<pre-revprop-change>
hook available.

=item $ra-E<gt>check_path($path, $revnum)

Kind of node at C<$path> in revision C<$revnum>.  A number which matches one
of these constants:
$SVN::Node::none, $SVN::Node::file,
$SVN::Node::dir, $SVN::Node::unknown.

=item $ra-E<gt>do_diff($revision, $target, $recurse, $ignore_ancestry, $versus_url, $editor)

=item $ra-E<gt>do_diff2($revision, $target, $recurse, $ignore_ancestry, $text_deltas, $versus_url, $editor)

Both of these return a L<SVN::Ra::Reporter> with which you can describe
a working copy.  It will then call methods on C<$editor> to indicates
the differences between the repository and the working copy.

The C<do_diff2> method was added in S<Subversion 1.4>.  It adds the
C<$text_deltas> option, which if false disables the generation of text
deltas on the editor.  With C<do_diff> text deltas are always generated.

    my $reporter = $ra->do_diff(1, '', 1, 0, $repos_url,
                                MyEditor->new);
    $reporter->set_path(...);
    $reporter->finish_report;

=item $ra-E<gt>do_status($target, $revision, $recurse, $editor)

Returns a L<SVN::Ra::Reporter> to which you can describe the status of
a working copy.  It will then call methods on C<$editor> to describe
the current status of the working copy compared to the repository.

=item $ra-E<gt>do_switch($revnum, $target, $recurse, $repos_url, $editor)

Returns a L<SVN::Ra::Reporter> with which you can describe a working copy.
It will then call methods on C<$editor> to indicate how to adjust the working
copy to switch it to revision C<$revnum> of C<$repos_url>.

=item $ra-E<gt>do_update($revision_to_update_to, $target, $recurse, $editor)

Returns a L<SVN::Ra::Reporter> object.  Call methods on the reporter to
describe the current state of your working copy (or whatever you're
updating).  After calling the reporter's C<finish_report()> method,
Subversion will generate calls to your C<$editor> to describe the
differences between what you already have and the state of the repository in
C<$revision_to_update_to>.

To update to the latest revision, pass C<$SVN::Core::INVALID_REVNUM> for
the first argument.

C<$target> should be the path to the part of the repository you are
interested in.  You won't be given information about changes outside this
path.  If you want everything, pass an empty string.

If C<$recurse> is true and the target is a directory, update
recursively; otherwise, update just the target and its immediate
entries, but not its child directories (if any).

All paths are relative to the URL used to open C<$ra>.

The caller may not perform any RA operations using C<$ra> before
finishing the report, and may not perform any RA operations using
C<$ra> from within the editing operations of C<$editor>.

This example shows the simplest update, where the client tells the reporter
that it has nothing to start with:

    my $reporter = $ra->do_update($revnum, '', 1, MyEditor->new);
    $reporter->set_path('', 0, 1, undef);
    $reporter->finish_report;

=item $ra-E<gt>get_commit_editor($logmsg, $callback, $callback_baton, $lock_tokens, $keep_locks)

=item $ra-E<gt>get_commit_editor2($logmsg, $callback, $callback_baton, $lock_tokens, $keep_locks)

Return an opaque editor object for committing a new revision to the
repository.  The return values should be passed to the
L<SVN::Delta::Editor|SVN::Delta/SVN::Delta::Editor> constructor to create an
editor object you can actually use.  For example:

    my $editor = SVN::Delta::Editor->new(
        $ra->get_commit_editor(
            "I'm going to commit some changes from within my Perl code.",
            \&commit_callback, undef, {}, 0));

Now that you've got your editor you can call methods on it to describe
changes in the tree you want to make, such as adding directories, changing
file contents, etc.  See L<SVN::Delta> for documentation of the editor
interface.

The C<$callback> function will be called during your call to the
C<$ed-E<gt>close_edit()> method, after the commit has succeeded.  It will
not be called if there were no changes to commit.  If you don't need it,
pass undef instead of a code ref.

C<get_commit_editor2> is identical to C<get_commit_editor> except for
the information passed to the callback function.  The new version, added
in S<Subversion 1.4>, will pass the callback a single value (TODO: I
can' test this, but it's probably an object or hash ref) which contains
all the information.  It also includes the error message from the
post-commit hook script, which is not available with C<get_commit_editor>.

The callback for the original version will be passed three arguments:

=over

=item *

Number of the new revision.

=item *

Date and time that the revision was committed, which will be exactly
the same value as its C<svn:date> revision property.  It will be in
this format: C<2006-04-05T12:17:48.180320Z>

=item *

The name of the author who committed the revision, which will be the same
as the C<svn:author> revision property.

=back

The undef in the argument list in the example above is the baton which is
meant to be passed to the commit callback, but it isn't.  This isn't a
problem since you can supply a closure as the callback so that it can get to
whatever variables you need.

The C<$logmsg> value should be a string which will be stored in the
C<svn:log> revision property.  If undef is passed instead then the
new revision won't have a C<svn:log> property.

C<$lock_tokens> should be a reference to a hash mapping the paths to
lock tokens to use for them.  I seems that with S<Subversion 1.2> this is
required, so if you aren't using any locks simply pass C<{}>.  In
S<Subversion 1.3.1> though it seems to be necessary to I<not> pass this
argument at all.

If C<$keep_locks> is true then locks on the files committed won't be
released by the commit.

The C<get_commit_editor()> method itself returns a list of two items, the
first of which (a C<_p_svn_delta_editor_t> object) is the actual editor.
The second is the editor baton.  Neither is of any use without wrapping the
pair of them in a L<SVN::Delta::Editor>.

=item $ra-E<gt>get_dated_revision($time)

TODO - this doesn't seem to work in S<Subversion 1.3>.

=item $ra-E<gt>get_dir($path, $revnum)

=item $ra-E<gt>get_dir2($path, $revnum, $dirent_fields)

Fetch the directory entries and properties of the directory at C<$path>
in revision C<$revnum>

A list of three values are returned.  The first is a reference to a hash
of directory entries.  The keys are the names of all the files and
directories in C<$path> (not full paths, just the filenames).  The values
are L<_p_svn_dirent_t|SVN::Core/_p_svn_dirent_t> objects, with all their
fields filled in.  The third parameter to C<get_dir2> allows you to
select particular fields.  TODO: I don't think the constants you'd use
to construct the C<$dirent_fields> value are provided in the Perl API.

The second value is a number, which is only valid if C<$revnum> is
C<$SVN::Core::INVALID_REVNUM>.  If that is the case then the latest revision
will be fetched, and the revision number (the HEAD revision) will be returned
as the second value.  Otherwise the revision number returned will be
completely arbitrary.

The third value returned will be a reference to a hash of all properties
on the directory.  This means I<all> properties: not just ones controlled by
the user and stored in the repository fs, but non-tweakable ones
generated by the SCM system itself (e.g. 'wcprops', 'entryprops', etc).

    my ($dirents, undef, $props) = $ra->get_dir('trunk/dir', 123);
    my ($dirents, $fetched_revnum, $props) = $ra->get_dir(
        'trunk/dir', $SVN::Core::INVALID_REVNUM);

=item $ra-E<gt>get_file($path, $revnum, $fh)

Fetch the contents and properties of the file at C<$path> in revision
C<$revnum>.  C<$fh> should be a Perl filehandle, to which the contents
of the file will be written, or undef if you don't need the file contents.

Note that C<$path> cannot end in a slash unless it is just '/'.

A list of two values are returned.  The first is a number, which is only
valid if C<$revnum> is C<$SVN::Core::INVALID_REVNUM>.  If that is the
case then the latest revision will be fetched, and the revision number
(the HEAD revision) will be returned as the first value.  Otherwise the
number returned will be completely arbitrary.

The second value returned will be a reference to a hash of all properties
on the file.  This means I<all> properties: not just ones controlled by
the user and stored in the repository fs, but non-tweakable ones
generated by the SCM system itself (e.g. 'wcprops', 'entryprops', etc).

    my (undef, $props) = $ra->get_file(
        'trunk/foo', 123, undef);

    open my $fh, '>', 'tmp_out'
        or die "error opening file: $!";
    my (undef, $props) = $ra->get_file(
        'trunk/foo', 123, $fh);

    my ($fetched_revnum, $props) = $ra->get_file(
        'trunk/foo', $SVN::Core::INVALID_REVNUM, $fh);

=item $ra-E<gt>get_file_revs($path, $start, $end, \&callback)

TODO - doesn't seem to work in Subversion 1.3

=item $ra-E<gt>get_latest_revnum

Return the number of the latest revision in the repository (HEAD).

=item $ra-E<gt>get_locations($path, $peg_revnum, \@location_revisions)

TODO - doesn't seem to work in Subversion 1.3

=item $ra-E<gt>get_lock($path)

Returns a L<_p_svn_lock_t|SVN::Core/_p_svn_lock_t> object containing
information about the lock at C<$path>, or undef if that path isn't
currently locked.

=item $ra-E<gt>get_locks($path)

TODO - doesn't seem to work in Subversion 1.3

=item $ra-E<gt>get_log(\@paths, $start, $end, $limit, $discover_changed_paths, $strict_node_history, \&callback)

For C<$limit> revisions from C<$start> to C<$end>, invoke the receiver
C<callback()> with information about the changes made in the revision
(log message, time, etc.).

The caller may not invoke any RA operations using C<$ra> from
within the callback function.  They may work in some situations, but
it's not guaranteed.

The first argument can be either a single string or a reference to an
array of strings.  Each of these indicates a path in the repository
which you are interested in.  Revisions which don't change any of these
paths (or files below them) will be ignored.  Simply pass '' if you don't
want to limit by path.

C<$start> and C<$end> should be revision numbers.  If C<$start> has a lower
value than C<$end> then the revisions will be produced in ascending order
(r1, r2, ...), otherwise in descending order.  If C<$start> is
C<$SVN::Core::INVALID_REVNUM> then it defaults to the latest revision.

TODO - the previous sentence should also be true of $end, but doing that
gets an error message in Subversion 1.3.

C<$limit> is a number indicating the maximum number of times that the
receiver C<callback()> should be called.  If it is 0, there will be no
limit.

If C<$discover_changed_paths> is true, then information about which changes
were made to which paths is passed to C<callback()>.

If C<$strict_node_history> is true, copy history will not be traversed
(if any exists) when harvesting the revision logs for each path.

The callback function will be given the following arguments:

=over

=item *

A reference to a hash of paths changed by the revision.  Only passed if
C<$discover_changed_paths> is true, otherwise undef is passed in its
place.

The hash's keys are the full paths to the files and directories changed.
The values are L<_p_svn_log_changed_path_t|SVN::Core/_p_svn_log_changed_path_t>
objects.

=item *

Revision number.

=item *

Name of user who made the change, or undef if not known.

=item *

Date and time the revision was committed.

=item *

Log message as a single string, or undef.

=item *

A pool object.

=back

This example prints some of the information received in a simple format,
showing which paths were changed in each revision, for all revisions starting
from the first:

    $ra->get_log('', 1, $ra->get_latest_revnum, 0, 1, 0,
                 \&log_callback);

    sub log_callback
    {
        my ($paths, $revnum, $user, $datetime, $logmsg) = @_;
        print "$datetime - $user - r$revnum\n";

        while (my ($path, $changes) = each %$paths) {
            print $changes->action, " $path\n";
            if ($changes->copyfrom_path) {
                print " from ", $changes->copyfrom_path,
                      " r", $changes->copyfrom_rev, "\n"
            }
        }

        print "\n";
    }

=item $ra-E<gt>get_repos_root

Returns the repository's root URL.  The value will not include
a trailing '/'.  The returned URL is guaranteed to be a prefix of the
session's URL.

=item $ra-E<gt>get_uuid

Returns the repository's UUID as a string.

=item $ra-E<gt>lock(\%path_revs, $comment, $steal_lock, \&callback)

TODO - doesn't seem to work in Subversion 1.3.2

=item $ra-E<gt>reparent($url)

Change the root URL of the session in C<$ra> to point to a different
path.  C<$url> must be in the same repository as the one C<$ra> is
already accessing.

New in S<Subversion 1.4>.

=item $ra-E<gt>replay($revnum, $low_water_mark, $send_deltas, $editor)

Call methods on C<$editor> to describe the changes made in the revisions
after C<$low_water_mark>, up to revision C<$revnum>.  This is like using
C<do_update()>, except that it doesn't return a reporter object, and so
you don't have to describe a working copy to it.  It assumes that you've
already got everything up to C<$low_water_mark>.

If C<$send_deltas> is true then file contents and property values will
be supplied, otherwise just filename changes.

New in S<Subversion 1.4>.

=item $ra-E<gt>rev_prop($revnum, $name)

Return the value of the unversioned property C<$name> from revision C<$revnum>.
Returns undef if there is no such property.

    print $ra->rev_prop(123, 'svn:date');

=item $ra-E<gt>rev_proplist($revnum)

Returns a reference to a hash containing all the unversioned properties
of revision C<$revnum>.

    my $props = $ra->rev_proplist(123);
    print $props->{'svn:log'};

=item $ra-E<gt>stat($path, $revnum)

Returns a L<_p_svn_dirent_t|SVN::Core/_p_svn_dirent_t> object containing
information about the file at C<$path> in revision C<$revnum>.

=item $ra-E<gt>unlock(\%path_tokens, $break_lock, \&callback)

TODO - doesn't seem to work in Subversion 1.3.2

=back

=cut

require SVN::Client;

my $ralib = SVN::_Ra::svn_ra_init_ra_libs(SVN::Core->gpool);

# Ra methods that returns reporter
my %reporter = map { $_ => 1 } qw(do_diff do_switch do_status do_update);
our $AUTOLOAD;

sub AUTOLOAD {
    my $class = ref($_[0]);
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    return unless $method =~ m/[^A-Z]/;

    my $self = shift;
    no strict 'refs';

    my $func = $self->{session}->can($method)
        or die "no such method $method";

    my @ret = $func->($self->{session}, @_);
    # XXX - is there any reason not to use \@ret in this line:
    return bless [@ret], 'SVN::Ra::Reporter' if $reporter{$method};
    return $#ret == 0 ? $ret[0] : @ret;
}

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    %$self = $#_ ? @_ : (url => $_[0]);

    if (defined($self->{auth})) {
        if (ref($self->{auth}) ne '_p_svn_auth_baton_t') {
            # If the auth is already set to a auth_baton ignore it
            # otherwise make an auth_baton and store the callbacks
            my ($auth_baton, $auth_callbacks) =
                SVN::Core::auth_open_helper($self->{auth});
            $self->{auth} = $auth_baton;
            $self->{auth_provider_callbacks} = $auth_callbacks;
        }
    } else {
        # no callback to worry about with a username provider so just call
        # auth_open directly
        $self->{auth} = SVN::Core::auth_open(
                             [SVN::Client::get_username_provider()]);
    }

    my $pool = $self->{pool} ||= SVN::Pool->new;
    my $callback = 'SVN::Ra::Callbacks';

    # custom callback namespace
    if ($self->{callback} && !ref($self->{callback})) {
        $callback = delete $self->{callback};
    }
    # instantiate callbacks
    $callback = (delete $self->{callback}) || $callback->new(auth => $self->{auth});

    $self->{session} = SVN::_Ra::svn_ra_open($self->{url}, $callback, $self->{config} || {}, $pool);
    return $self;
}

sub DESTROY { }

package _p_svn_ra_session_t;
use SVN::Base qw(Ra svn_ra_);

package SVN::Ra::Reporter;
use SVN::Base qw(Ra svn_ra_reporter2_);

=head1 SVN::Ra::Reporter

The L<SVN::Ra> methods C<do_diff>, C<do_status>, C<do_switch>, and
C<do_update> all return a SVN::Ra::Reporter object, which can be used
to describe the working copy (or other available data) which the client has.
Subversion uses this to figure out what new information should be provided
through a tree delta editor.

Objects of this class are actually simple wrappers around underlying
C<svn_ra_reporter2_t> objects and their associated baton.

=head2 METHODS

=over

=item $reporter-E<gt>set_path($path, $revision, $start_empty, $lock_token, $pool)

Describe a working copy C<$path> as being at a particular C<$revision>.

If C<$start_empty> is true and C<$path> is a directory, the
implementor should assume the directory has no entries or properties.

This will I<override> any previous C<set_path()> calls made on parent
paths.  C<$path> is relative to the URL specified in C<SVN::Ra-E<gt>open()>
or C<SVN::Ra-E<gt>new()>.

If C<$lock_token> is not undef, it is the lock token for C<$path> in the WC.

All temporary allocations are done in C<$pool>.

=item $reporter-E<gt>delete_path($path, $pool)

Describe a working copy C<$path> as missing.

All temporary allocations are done in C<$pool>.

=item $reporter-E<gt>link_path($path, $url, $revision, $start_empty, $lock_token, $pool)

Like C<set_path()>, but differs in that C<$path> in the working copy
(relative to the root of the report driver) isn't a reflection of
C<$path> in the repository (relative to the URL specified when
opening the RA layer), but is instead a reflection of a different
repository C<$url> at C<$revision>.

If C<$start_empty> is true and C<$path> is a directory,
the implementor should assume the directory has no entries or props.

If C<$lock_token> is not undef, it is the lock token for C<$path> in the WC.

All temporary allocations are done in C<$pool>.

=item $reporter-E<gt>finish_report($pool)

Call this when the state report is finished; any directories
or files not explicitly 'set' are assumed to be at the
baseline revision originally passed into C<do_update()>.  No other
reporting functions, including C<abort_report()>, should be called after
calling this function.

=item $reporter-E<gt>abort_report($pool)

If an error occurs during a report, this method should cause the
filesystem transaction to be aborted and cleaned up.  No other reporting
methods should be called after calling this method.

=back

=cut

our $AUTOLOAD;
sub AUTOLOAD {
    my $class = ref($_[0]);
    $AUTOLOAD =~ s/^${class}::(SUPER::)?//;
    return if $AUTOLOAD =~ m/^[A-Z]/;

    my $self = shift;
    no strict 'refs';

    my $method = $self->can("invoke_$AUTOLOAD")
        or die "no such method $AUTOLOAD";

    no warnings 'uninitialized';
    $method->(@$self, @_);
}

package SVN::Ra::Callbacks;

=head1 SVN::Ra::Callbacks

This is the wrapper class for C<svn_ra_callback_t>.  To supply custom
callbacks to SVN::Ra, subclass this class and override the member
functions.

=cut

require SVN::Core;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    %$self = @_;
    return $self;
}

sub open_tmp_file {
    local $^W; # silence the warning for unopened temp file
    my ($self, $pool) = @_;
    my ($fd, $name) = SVN::Core::io_open_unique_file(
        ( File::Temp::tempfile(
            'XXXXXXXX', OPEN => 0, DIR => File::Spec->tmpdir
        ))[1], 'tmp', 1, $pool
    );
    return $fd;
}

sub get_wc_prop {
    return undef;
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
