use strict;
use warnings;

use SVN::Core;
use SVN::Wc;

package SVN::Client;
my @_all_fns;
BEGIN {
    @_all_fns =
        qw( add add2 add3 add4 add_to_changelist blame blame2 blame3 blame4
            cat cat2 checkout checkout2 checkout3 cleanup
            commit commit2 commit3 commit4 copy copy2 copy3 copy4
            create_context delete delete2 delete3 diff diff2 diff3 diff4
            diff_peg diff_peg2 diff_peg3 diff_peg4
            diff_summarize diff_summarize2 diff_summarize_dup
            diff_summarize_peg diff_summarize_peg2
            export export2 export3 export4 import import2 import3
            info info2 invoke_blame_receiver invoke_blame_receiver2
            invoke_diff_summarize_func list list2 lock
            log log2 log3 log4 log5 ls ls2 ls3
            merge merge2 merge3 merge_peg merge_peg2 merge_peg3
            mkdir mkdir2 mkdir3 mkdir4 move move2 move3 move4 move5
            open_ra_session propget propget2 propget3
            proplist proplist2 proplist3 propset propset2 propset3
            relocate remove_from_changelist resolve resolved
            revert revert2 revprop_get revprop_list revprop_set
            status status2 status3 status4 switch switch2
            unlock update update2 update3 update4
            url_from_path uuid_from_path uuid_from_url version
          );

    require SVN::Base;
    import SVN::Base (qw(Client svn_client_), @_all_fns);
}

=head1 NAME

SVN::Client - Subversion client functions

=head1 SYNOPSIS

    use SVN::Client;
    my $client = new SVN::Client();

    # setup to handle authentication the same as the command line client
    my $config_dir = undef; # use default location
    my $config = SVN:Core::config_get_config($config_dir);
    my $config_category = $cfg->{SVN::Core::CONFIG_CATEGORY_CONFIG};
    $client->auth(
      SVN::Core::cmdline_create_auth_baton(0,           #non_interactive
                                           undef,       #username
                                           undef,       #password
                                           $config_dir,
                                           0,           #no_auth_cache
                                           0,           #trust_server_cert
                                           $config_category,
                                           undef)       #cancel_callback
    );

    # Use first argument as target and canonicalize it before using
    my $target;
    if (SVN::Core::path_is_url($ARGV[0])) {
      $target = SVN::Core::uri_canonicalize($ARGV[0]);
    } else {
      $target = SVN::Core::dirent_canonicalize($ARGV[0]);
    }

    # fetch the head revision of the target
    $client->cat(\*STDOUT, $target, 'HEAD');


=head1 DESCRIPTION

SVN::Client wraps the highest level of functions provided by
subversion to accomplish specific tasks in an object oriented API.
Methods are similar to the functions provided by the C API and
as such the documentation for it may be helpful in understanding
this interface.

There are a few notable differences from the C API.  Most C function
calls take a svn_client_ctx_t pointer as the next to last parameter.
The Perl method calls take a SVN::Client object as the first parameter.
This allows method call invocation of the methods to be possible.  For
example, the following are equivalent:

  SVN::Client::add($client,$path, $recursive, $pool);
  $client->add($path, $recursive, $pool);

Many of the C API calls also take a apr_pool_t pointer as their last
argument.  The Perl bindings generally deal with this for you and
you do not need to pass a pool parameter.  However, you may still
pass a pool parameter as the last parameter to override the automatic
handling of this for you.

Users of this interface should not directly manipulate the underlying hash
values but should use the respective attribute methods.  Many of these
attribute methods do other things, especially when setting an attribute,
besides simply manipulating the value in the hash.

=head1 PARAMETER NOTES

The client methods described below take a variety of parameters.  Many of
them are similar.  Methods accepting parameters named below will follow
the rules below or will be noted otherwise in the method description.

=over 4

=item $client

An SVN::Client object that you get from the constructor.

=item $url

This is a URL to a subversion repository.

=item $path

This is a path to a file or directory on the local file system.  Paths need
to be canonicalized before being passed into the Subversion APIs.  Paths on
the local file system are called dirents and can be canonicalized by calling
C<SVN::Core::dirent_canonicalize>.

=item $paths

This argument can either be a single $path (as defined above) or a reference
to an array of them.

=item $target

This is a path to a file or directory in a working copy or a URL to a file or
directory in a subversion repository.  Both paths and URLs need to be
canonicalized before being passed into the Subversion APIs.  Paths on the local
file system are called dirents and can be canonicalized by calling 
C<SVN::Core::dirent_canonicalize>.  URLs can be canonicalized by calling
C<SVN::Core::uri_canonicalize>.

=item $targets

This argument can either be a single $target (as defined above) or a reference
to an array of them.

=item $revision

This specifies a revision in the Subversion repository.  You can specify a
revision in several ways.  The easiest and most obvious is to directly
provide the revision number.  You may also use the strings (aka revision
keywords) 'HEAD', 'BASE', 'COMMITTED', and 'PREV' which have the same
meanings as in the command line client.  When referencing a working copy
you can use the string 'WORKING" to reference the BASE plus any local
modifications.  C<undef> may be used to specify an unspecified revision.
You may also pass a date by specifying the date inside curly braces
'{}'.  The date formats accepted are the same as the command line client
accepts. Finally a C<_p_svn_opt_revision_t> object is accepted
(which may have been returned by some Subversion function).

=item $recursive $nonrecursive.

A boolean parameter that specifies if the action should follow directories.  It
should only be 1 or 0.  $recursive means, 1 means to descend into directories,
0 means not to.  $nonrecursive has the inverse meaning.

=item $pool

Pool is always an option parameter.  If you wish to pass a pool parameter it
should be a SVN::Pool or an apr_pool_t object.

=back

=head1 METHODS

The following methods are available:

=over 4

=item $client = SVN::Client-E<gt>new( %options );

This class method constructs a new C<SVN::Client> object and returns
a reference to it.

Key/value pair arguments may be provided to set up the initial state
of the user agent.  The following methods correspond to attribute
methods described below:

    KEY                    DEFAULT
    ----------             ----------------------------------------
    auth                   auth_baton initiated with providers that
                           read cached authentication options from
                           the subversion config only.

    cancel                 undef

    config                 Hash containing the config from the
                           default subversion config file location.

    log_msg                undef

    notify                 undef

    pool                   A new pool is created for the context.

=cut

sub new
{
    my $class = shift;
    my $self = bless {}, $class;
    my %args = @_;

    $self->{'ctx'} = SVN::_Client::svn_client_create_context();

    if (defined($args{'auth'}))
    {
        $self->auth($args{'auth'});
    } else {
        $self->auth([SVN::Client::get_username_provider(),
                     SVN::Client::get_simple_provider(),
                     SVN::Client::get_ssl_server_trust_file_provider(),
                     SVN::Client::get_ssl_client_cert_file_provider(),
                     SVN::Client::get_ssl_client_cert_pw_file_provider(),
                    ]);
    }

    {
        my $pool_type = ref($args{'pool'});
        if ($pool_type eq 'SVN::Pool' ||
            $pool_type eq '_p_apr_pool_t')
        {
            $self->{'pool'} = $args{'pool'};
        } else {
            $self->{'pool'} = new SVN::Pool();
        }
    }

    # If we're passed a config use it, otherwise get the default
    # config.
    if (defined($args{'config'}))
    {
        if (ref($args{'config'}) eq 'HASH')
        {
            $self->config($args{'config'});
        }
    } else {
        $self->config(SVN::Core::config_get_config(undef));
    }

    if (defined($args{'notify'}))
    {
        $self->notify($args{'notify'});
    }

    if (defined($args{'log_msg'}))
    {
        $self->log_msg($args{'log_msg'});
    }

    if (defined($args{'cancel'}))
    {
        $self->cancel($args{'cancel'});
    }

    return $self;
}

=item $client-E<gt>add($path, $recursive, $pool);

Similar to $client-E<gt>add2(), but with $force always set to FALSE.

=item $client-E<gt>add2($path, $recursive, $force, $pool);

Similar to $client-E<gt>add3(), but with $no_ignore always set to FALSE.

=item $client-E<gt>add3($path, $recursive, $force, $no_ignore, $pool);

Similar to $client-E<gt>add4(), but with $add_parents always set to FALSE and
$depth set according to $recursive; if TRUE, then depth is
$SVN::Depth::infinity, if FALSE, then $SVN::Depth::empty.

=item $client-E<gt>add4($path, $depth, $force, $no_ignore, $add_parents, $pool);

Schedule a working copy $path for addition to the repository.

If $depth is $SVN::Depth::empty, add just $path and nothing below it.  If
$SVN::Depth::files, add $path and any file children of $path.  If 
$SVN::Depth::immediates, add $path, any file children, and any immediate
subdirectories (but nothing underneath those subdirectories).  If 
$SVN::Depth::infinity, add $path and everything under it fully recursively.

$path's parent must be under revision control already (unless $add_parents is
TRUE), but $path is not.

Unless $force is TRUE and $path is already under version control, returns an
$SVN::Error::ENTRY_EXISTS object.  If $force is set, do not error on
already-versioned items.  When used with $depth set to $SVN::Depth::infinity
it will enter versioned directories; scheduling unversioned children. 

Calls the notify callback for each added item.

If $no_ignore is FALSE, don't add any file or directory (or recurse into any
directory) that is unversioned and found by recursion (as opposed to being the
explicit target $path) and whose name matches the svn:ignore property on its
parent directory or the global-ignores list in $client->config.  If $no_ignore is
TRUE, do include such files and directories.  (Note that an svn:ignore property
can influence this behaviour only when recursing into an already versioned
directory with $force).

If $add_parents is TRUE, recurse up $path's directory and look for a versioned
directory.  If found, add all intermediate paths between it and $path.  If not
found return $SVN::Error::NO_VERSIONED_PARENT.

Important: this is a B<scheduling> operation.  No changes will happen
to the repository until a commit occurs.  This scheduling can be
removed with $client-E<gt>revert().

No return.

=item $client-E<gt>blame($target, $start, $end, \&receiver, $pool);

Invoke \&receiver subroutine on each line-blame item associated with revision
$end of $target, using $start as the default source of all blame.

An Error will be raised if either $start or $end is undef.

No return.

The blame receiver subroutine receives the following arguments:
$line_no, $revision, $author, $date, $line, $pool

$line_no is the line number of the file (starting with 0).
The line was last changed in revision number $revision
by $author on $date and the contents were $line.

The blame receiver subroutine can return an svn_error_t object
to return an error.  All other returns will be ignored.
You can create an svn_error_t object with SVN::Error::create().

=item $client-E<gt>cat(\*FILEHANDLE, $target, $revision, $pool);

Outputs the content of the file identified by $target and $revision to the
FILEHANDLE.  FILEHANDLE is a reference to a filehandle.

If $target is not a local path and if $revision is 'PREV' (or some
other kind that requires a local path), then an error will be raised,
because the desired revision can not be determined.

=item $client-E<gt>checkout($url, $path, $revision, $recursive, $pool);

Similar to $client-E<gt>checkout2(), but with $peg_revision always set to undef (unspecified) and $ignore_externals always set to FALSE.

=item $client-E<gt>checkout2($url, $path, $peg_revision, $revision, $recursive, $ignore_externals, $pool);

Similar to $client-E<gt>checkout3(), but with $allow_unver_obstructions always set
to FALSE, and $depth set according to $recurse: if $recurse is TRUE, $depth is
$SVN::Depth::infinity, if $recurse is FALSE, set $depth to $SVN::Depth::files.

=item $client-E<gt>checkout3($url, $path, $preg_revision, $revision, $depth, $ignore_externals, $allow_unver_obstructions, $pool);

Checkout a working copy of $url at $revision using $path as the root directory
of the newly checked out working copy.

The $peg_revision sets the revision at which the path in the $url is treated as representing.

$revision must be a number, 'HEAD', or a date.  If $revision does not
meet these requirements the $SVN::Error::CLIENT_BAD_REVISION is raised.

$depth is one of the constants in SVN::Depth and specifies the depth of the
operation.  If set to $SVN::Depth::unknown, then behave as if for
$SVN::Depth::infinity, except in the case of resuming a previous checkout of
$path (i.e. updating) in which case use the depth of the existing working copy.

$ignore_exteranls if set to TRUE the operation will ignore external definitions.

$allow_unver_obstructions if set to TRUE the operation will tolerate existing
unversioned items that obstruct incoming paths.  Only obstructions of the same
type (file or dir) as the added item are tolerated.  The text of obstructing
files is left as-is, effectively treating it as a user modification after the
checkout.  Working properties of obstructing items are set equal to the base
properties.  If set to FALSE, then abort if there are any unversioned
obstructing items.

Returns the value of the revision actually checked out of the repository.

=item $client-E<gt>cleanup($dir, $pool);

Recursively cleanup a working copy directory, $dir, finishing any incomplete
operations, removing lockfiles, etc.

=item $client-E<gt>commit($targets, $nonrecursive, $pool);

Commit files or directories referenced by target.  Will use the log_msg
callback to obtain the log message for the commit.

If $targets contains no paths (zero elements), then does nothing and
immediately returns without error.

Calls the notify callback as the commit progresses with any of the following
actions: $SVN::Wc::Notify::Action::commit_modified,
$SVN::Wc::Notify::Action::commit_added,
$SVN::Wc::Notify::Action::commit_deleted,
$SVN::Wc::Notify::Action::commit_replaced,
$SVN::Wc::Notify::Action::commit_postfix_txdelta.

Use $nonrecursive to indicate that subdirectories of directory targets
should be ignored.

Returns a svn_client_commit_info_t object.  If the revision member of the
commit information object is $SVN::Core::INVALID_REVNUM and no error was
raised, then the commit was a no-op; nothing needed to be committed.

=item $client-E<gt>copy($src_target, $src_revision, $dst_target, $pool);

Copies $src_target to $dst_target.

$src_target must be a file or directory under version control, or the URL
of a versioned item in the repository.  If $src_target is a URL,
$src_revision is used to choose the revision from which to copy the
$src_target.  $dst_path must be a file or directory under version control,
or a repository URL, existing or not.

If $dst_target is a URL, immediately attempt to commit the copy action
to the repository.  The log_msg callback will be called to query for a commit
log message.  If the commit succeeds, return a svn_client_commit_info_t
object.

If $dst_target is not a URL, then this is just a variant of $client-E<gt>add(),
where the $dst_path items are scheduled for addition as copies.  No changes
will happen to the repository until a commit occurs.  This scheduling can be
removed with $client-E<gt>revert().  undef will be returned in this case.

Calls the notify callback for each item added at the new location, passing
the new, relative path of the added item.

=item $client-E<gt>delete($targets, $force, $pool);

Delete items from a repository or working copy.

If the paths in $targets are URLs, immediately attempt to commit a deletion
of the URLs from the repository.  The log_msg callback will be called to
query for a commit log message.  If the commit succeeds, return a
svn_client_commit_info_t object.  Every path must belong to the same
repository.

Else, schedule the working copy paths in $targets for removal from the
repository.  Each path's parent must be under revision control.  This is
just a B<scheduling> operation.  No changes will happen to the repository
until a commit occurs.  This scheduling can be removed with $client-E<gt>revert().
If a path is a file it is immediately removed from the working copy.  If
the path is a directory it will remain in the working copy but all the files,
and all unversioned items it contains will be removed.  If $force is not set
then this operation will fail if any path contains locally modified and/or
unversioned items.  If $force is set such items will be deleted.

The notify callback is called for each item deleted with the path of
the deleted item.

Has no return.

=item $client-E<gt>diff($diff_options, $target1, $revision1, $target2, $revision2, $recursive, $ignore_ancestry, $no_diff_deleted, $outfile, $errfile, $pool);

Produces diff output which describes the delta between $target1 at
$revision1 and $target2 at $revision2.  They both must represent the same
node type (i.e. they most both be directories or files).  The revisions
must not be undef.

Prints the output of the diff to the filename or filehandle passed as
$outfile, and any errors to the filename or filehandle passed as $errfile.

Use $ignore_ancestry to control whether or not items being diffed will be
checked for relatedness first.  Unrelated items are typically transmitted to
the editor as a deletion of one thing and the addition of another, but if this
flag is true, unrelated items will be diffed as if they were related.

If $no_diff_deleted is true, then no diff output will be generated on deleted
files.

$diff_options is a reference to an array of additional arguments to pass to
diff process invoked to compare files.  You'll usually just want to use [] to
pass an empty array to return a unified context diff (like `diff -u`).

Has no return.

=item $client-E<gt>diff_summarize($target1, $revision1, $target2, $revision2, $recursive, $ignore_ancestry, \&summarize_func, $pool);

Produce a diff summary which lists the changed items between $target1
at $revision1 and $target2 at $revision2 without creating text deltas.
$target1 and $target2 can be either working-copy paths or URLs.

The function may report false positives if $ignore_ancestry is false,
since a file might have been modified between two revisions, but still
have the same contents.

Calls \&summarize_func with with a svn_client_diff_summarize_t structure
describing the difference.

See diff() for a description of the other parameters.

Has no return.

=item $client-E<gt>export($from, $to, $revision, $force, $pool);

Export the contents of either a subversion repository or a subversion
working copy into a 'clean' directory (meaning a directory with no
administrative directories).

$from is either the path to the working copy on disk, or a URL
to the repository you wish to export.

$to is the path to the directory where you wish to create the exported
tree.

$revision is the revision that should be exported, which is only used
when exporting from a repository.  It may be undef otherwise.

The notify callback will be called for the items exported.

Returns the value of the revision actually exported or
$SVN::Core::INVALID_REVNUM for local exports.

=item $client-E<gt>import($path, $url, $nonrecursive, $pool);

Import file or directory $path into repository directory $url at head.

If some components of $url do not exist then create parent directories
as necessary.

If $path is a directory, the contents of that directory are imported
directly into the directory identified by $url.  Note that the directory
$path itself is not imported; that is, the basename of $path is not part
of the import.

If $path is a file, then the dirname of $url is the directory receiving the
import.  The basename of $url is the filename in the repository.  In this case
if $url already exists, raise an error.

The notify callback (if defined) will be called as the import progresses, with
any of the following actions: $SVN::Wc::Notify::Action::commit_added,
$SVN::Wc::Notify::Action::commit_postfix_txdelta.

Use $nonrecursive to indicate that imported directories should not recurse
into any subdirectories they may have.

Uses the log_msg callback to determine the log message for the commit when
one is needed.

Returns a svn_client_commit_info_t object.

=item $client-E<gt>info($path_or_url, $peg_revision, $revision, \&receiver, $recurse);

Invokes \&receiver passing it information about $path_or_url for $revision.
The information returned is system-generated metadata, not the sort of
"property" metadata created by users.  For methods available on the object
passed to \&receiver, B<see svn_info_t>.

If both revision arguments are either svn_opt_revision_unspecified or NULL,
then information will be pulled solely from the working copy; no network
connections will be made.

Otherwise, information will be pulled from a repository.  The actual node
revision selected is determined by the $path_or_url as it exists in
$peg_revision.  If $peg_revision is undef, then it defaults to HEAD for URLs
or WORKING for WC targets.

If $path_or_url is not a local path, then if $revision is PREV (or some other
kind that requires a local path), an error will be returned, because the
desired revision cannot be determined.

Uses the authentication baton cached in ctx to authenticate against the
repository.

If $recurse is true (and $path_or_url is a directory) this will be a recursive
operation, invoking $receiver on each child.

 my $receiver = sub {
     my( $path, $info, $pool ) = @_;
     print "Current revision of $path is ", $info->rev, "\n";
 };
 $client->info( 'foo/bar.c', undef, 'WORKING', $receiver, 0 );

=item $client-E<gt>log5($targets, $peg_revision, $revision_ranges, $limit, $discover_changed_paths, $strict_node_history, $include_merged_revisions, $revprops, \&log_entry_receiver, $pool);

Invoke C<log_entry_receiver> on each log message from
each revision range in C<$revision_ranges> in turn,
inclusive (but never invoke C<log_entry_receiver> on a given log message more
than once).

C<$targets> is a reference to an array of either a URL followed by zero 
or more relative paths, or 1 working copy path, for which log
messages are desired. If the array contains only a single element
you may set C<$targets> to this element instead.
C<log_entry_receiver> is invoked only on messages whose
revisions involved a change to some path in C<$targets>.

C<$peg_revision> indicates in which revision C<$targets> are valid. 
If C<$peg_revision> is C<undef>, it defaults to 'HEAD'
for URLs or 'WORKING' for WC paths.

C<$revision_ranges> is either a single I<revision range> or a reference
to an array of them. A I<revision range> may be specified
as a reference to a two-element array C<[$start, $end]>
of L<$revision|/$revision>s or a 
L<SVN::Core::svn_opt_revision_range_t|SVN::Core/svn_opt_revision_range_t> 
object. Examples:

  $revision_ranges = ['HEAD', 1];
  $revision_ranges = [[2, 3], [5, 8], [13, 21]];

If C<$limit> is non-zero only invoke C<log_entry_receiver> 
on the first C<$limit> logs.

If C<$discover_changed_paths> is true, then the I<changed_paths2> field 
in the C<$log_entry> argument to C<log_entry_receiver> will be
populated on each invocation.  I<Note:> The I<text_modified> and
I<props_modified> fields of the I<changed_paths2> structure may have the value
C<$SVN::Tristate::unknown> if the repository does not report that information.

If C<$strict_node_history> is true, copy history (if any exists) will
not be traversed while harvesting revision logs for each target.

If C<$include_merged_revisions> is true, log information for revisions
which have been merged to C<$targets> will also be returned.

If C<$revprops> is C<undef>, retrieve all revision properties.
Otherwise C<$revpros> should be a reference to an array of
property names and only these properties will be retrieved
(i.e. none if the array is empty).

Use C<$pool> for any temporary allocation.

Calls the notify subroutine with a C<$SVN::Wc::Notify::Action::skip> 
signal on any unversioned C<$targets>.

The C<log_entry_receiver> takes the following arguments:
C<$log_entry, $pool>.  C<$log_entry> is a 
L<SVN::Core::svn_log_entry_t|SVN::Core/svn_log_entry_t> object.

=item $client-E<gt>log4($targets, $peg_revision, $start, $end, $limit, $discover_changed_paths, $strict_node_history, $include_merged_revisions, $revprops, \&log_entry_receiver, $pool);

Similar to C<$client-E<gt>log5()>, 
but takes explicit C<$start> and C<$end> parameters
instead of C<$revision_ranges>.

Deprecated.

=item $client-E<gt>log3($targets, $peg_revision, $start, $end, $limit, $discover_changed_paths, $strict_node_history, \&log_message_receiver, $pool);

Similar to C<$client-E<gt>log4()>, but using C<log_message_receiver>
instead of C<log_entry_receiver>.  Also, C<$include_merged_revisions> 
is false and C<$revprops> is [qw( svn:author svn:date and svn:log )].

The C<log_message_receiver> takes the following arguments:
C<$changed_paths, $revision, $author, $date, $message, $pool>.
It is called once for each log C<$message> from the C<$revision>
on C<$date> by C<$author>.  C<$author>, C<$date> or C<$message> 
may be C<undef>.

If C<$changed_paths> is defined it references a hash with the keys
every path committed in C<$revision>; the values are 
L<SVN::Core::svn_log_changed_path_t|SVN::Core/svn_log_changed_path_t>
objects.

Deprecated.

=item $client-E<gt>log2($targets, $start, $end, $limit, $discover_changed_paths, $strict_node_history, \&log_message_receiver, $pool);

Similar to C<$client-E<gt>log3()>, but with C<$peg_revision> set to C<undef>.

Deprecated.

=item $client-E<gt>log($targets, $start, $end, $discover_changed_paths, $strict_node_history, \&log_message_receiver, $pool);

Similar to C<$client-E<gt>log2()>, but with C<$limit> set to 0.

I<Special case for repositories at revision 0:>
If C<$start> is 'HEAD' and C<$end> is 1, then handle an empty (no revisions)
repository specially: instead of erroring because requested revision 1
when the highest revision is 0, just invoke 
C<log_message_receiver> on revision 0,
passing C<undef> to C<$changed_paths> and empty strings for the author and date.
This is because that particular combination of C<$start> 
and C<$end> usually indicates
the common case of log invocation; the user wants to see all log messages from
youngest to oldest, where the oldest commit is revision 1.  That works fine,
except there are no commits in the repository, hence this special case.

Deprecated.

=item $client-E<gt>ls($target, $revision, $recursive, $pool);

Returns a hash of svn_dirent_t objects for $target at $revision.

If $target is a directory, returns entries for all of the directories'
contents.  If $recursive is true, it will recurse subdirectories in $target.

If $target is a file only return an entry for the file.

If $target is non-existent, raises the $SVN::Error::FS_NOT_FOUND
error.

=item $client-E<gt>merge($src1, $rev1, $src2, $rev2, $target_wcpath, $recursive, $ignore_ancestry, $force, $dry_run, $pool);

Merge changes from $src1/$rev1 to $src2/$rev2 into the working-copy path
$target_wcpath.

$src1 and $src2 are either URLs that refer to entries in the repository, or
paths to entries in the working copy.

By 'merging', we mean: apply file differences and schedule additions &
deletions when appropriate.

$src1 and $src2 must both represent the same node kind; that is, if $src1
is a directory, $src2 must also be, and if $src1 is a file, $src2 must also be.

If either $rev1 or $rev2 is undef raises the $SVN::Error::CLIENT_BAD_REVISION
error.

If $recursive is true (and the URLs are directories), apply changes recursively;
otherwise, only apply changes in the current directory.

Use $ignore_ancestry to control whether or not items being diffed will be
checked for relatedness first.  Unrelated items are typically transmitted
to the editor as a deletion of one thing and the addition of another, but
if this flag is true, unrelated items will be diffed as if they were related.

If $force is not set and the merge involves deleting locally modified or
unversioned items the operation will raise an error.  If $force is set such
items will be deleted.

Calls the notify callback once for each merged target, passing the targets
local path.

If $dry_run is true the merge is carried out, and the full notification
feedback is provided, but the working copy is not modified.

Has no return.

=item $client-E<gt>mkdir($targets, $pool);

Similar to $client-E<gt>mkdir2() except it returns an svn_client_commit_info_t
object instead of a svn_commit_info_t object.

=item $client-E<gt>mkdir2($targets, $pool);

Similar to $client-E<gt>mkdir3(), but with $make_parents always FALSE, and
$revprop_hash always undef.

=item $client-E<gt>mkdir3($targets, $make_parents, $revprop_hash, $pool);

Similar to $client-E<gt>mkdir4(), but returns a svn_commit_info_t object rather
than through a callback function.

=item $client-E<gt>mkdir4($targets, $make_parents, $revprop_hash, \&commit_callback, $pool);

Create a directory, either in a repository or a working copy.

If $targets contains URLs, immediately attempts to commit the creation of the
directories in $targets in the repository.  Returns a svn_client_commit_info_t
object.

Else, create the directories on disk, and attempt to schedule them for addition.
In this case returns undef.

If $make_parents is TRUE, create any non-existent parent directories also.

If not undef, $revprop_hash is a reference to a hash table holding additional
custom revision properites (property names mapped to strings) to be set on the
new revision in the event that this is a committing operation.  This hash
cannot contain any standard Subversion properties.

Calls the log message callback to query for a commit log message when one is
needed.

Calls the notify callback when the directory has been created (successfully)
in the working copy, with the path of the new directory.  Note this is only
called for items added to the working copy.

If \&commit_callback is not undef, then for each successful commit, call
\&commit_callback with the svn_commit_info_t object for the commit.

=item $client-E<gt>move($src_path, $src_revision, $dst_path, $force, $pool);

Move $src_path to $dst_path.

$src_path must be a file or directory under version control, or the URL
of a versioned item in the repository.

If $src_path is a repository URL:

* $dst_path must also be a repository URL (existent or not).

* $src_revision is used to choose the revision from which to copy the
$src_path.

* The log_msg callback will be called for the commit log message.

* The move operation will be immediately committed.  If the commit succeeds,
returns a svn_client_commit_info_t object.

If $src_path is a working copy path

* $dst_path must also be a working copy path (existent or not).

* $src_revision is ignored and may be undef.  The log_msg callback will
not be called.

* This is a scheduling operation.  No changes will happen to the repository
until a commit occurs.  This scheduling can be removed with $client-E<gt>revert().
If $src_path is a file it is removed from the working copy immediately.
If $src_path is a directory it will remain in the working copy but all
files, and unversioned items, it contains will be removed.

* If $src_path contains locally modified and/or unversioned items and $force is
not set, the copy will raise an error.  If $force is set such items will be
removed.

The notify callback will be called twice for each item moved, once to
indicate the deletion of the moved node, and once to indicate the addition
of the new location of the node.

=item $client-E<gt>propget($propname, $target, $revision, $recursive, $pool);

Returns a reference to a hash containing paths or URLs, prefixed by $target (a
working copy or URL), of items for which the property $propname is set, and
whose values represent the property value for $propname at that path.

=item $client-E<gt>proplist($target, $revision, $recursive, $pool);

Returns a reference to an array of svn_client_proplist_item_t objects.

For each item the node_name member of the proplist_item object contains
the name relative to the same base as $target.

If $revision is undef, then get properties from the working copy, if
$target is a working copy, or from the repository head if $target is a URL.
Else get the properties as of $revision.

If $recursive is false, or $target is a file, the returned array will only
contain a single element.  Otherwise, it will contain one entry for each
versioned entry below (and including) $target.

If $target is not found, raises the $SVN::Error::ENTRY_NOT_FOUND error.

=item $client-E<gt>propset($propname, $propval, $target, $recursive, $pool);

Set $propname to $propval on $target (a working copy or URL path).

If $recursive is true, then $propname will be set recursively on $target
and all children.  If $recursive is false, and $target is a directory,
$propname will be set on B<only> $target.

A $propval of undef will delete the property.

If $propname is an svn-controlled property (i.e. prefixed with svn:),
then the caller is responsible for ensuring that $propval is UTF8-encoded
and uses LF line-endings.

=item $client-E<gt>relocate($dir, $from, $to, $recursive, $pool);

Modify a working copy directory $dir, changing any repository URLs that
begin with $from to begin with $to instead, recursing into subdirectories if
$recursive is true.

Has no return.

=item $client-E<gt>resolved($path, $recursive, $pool);

Removed the 'conflicted' state on a working copy path.

This will not semantically resolve conflicts; it just allows $path to be
committed in the future.  The implementation details are opaque.  If
$recursive is set, recurse below $path, looking for conflicts to
resolve.

If $path is not in a state of conflict to begin with, do nothing.

If $path's conflict state is removed, call the notify callback with the
$path.

=item $client-E<gt>revert($paths, $recursive, $pool);

Restore the pristine version of a working copy $paths, effectively undoing
any local mods.

For each path in $paths, if it is a directory and $recursive
is true, this will be a recursive operation.

=item $client-E<gt>revprop_get($propname, $url, $revision, $pool);

Returns two values, the first of which is the value of $propname on revision
$revision in the repository represented by $url.  The second value is the
actual revision queried.

Note that unlike its cousin $client-E<gt>propget(), this routine doesn't affect
working copy at all; it's a pure network operation that queries an
B<unversioned> property attached to a revision.  This can be used to query
log messages, dates, authors, and the like.

=item $client-E<gt>revprop_list($url, $revision, $pool);

Returns two values, the first of which is a reference to a hash containing
the properties attached to $revision in the repository represented by $url.
The second value is the actual revision queried.

Note that unlike its cousin $client-E<gt>proplist(), this routine doesn't read a
working copy at all; it's a pure network operation that reads B<unversioned>
properties attached to a revision.

=item $client-E<gt>revprop_set($propname, $propval, $url, $revision, $force, $pool);

Set $propname to $propval on revision $revision in the repository represented
by $url.

Returns the actual revision affected.  A $propval of undef will delete the
property.

If $force is true, allow newlines in the author property.

If $propname is an svn-controlled property (i.e. prefixed with svn:), then
the caller is responsible for ensuring that the value is UTF8-encoded and
uses LF line-endings.

Note that unlike its cousin $client-E<gt>propset(), this routine doesn't affect
the working copy at all; it's a pure network operation that changes an
B<unversioned> property attached to a revision.  This can be used to tweak
log messages, dates, authors, and the like.  Be careful: it's a lossy
operation, meaning that any existing value is replaced with the new value,
with no way to retrieve the prior value.

Also note that unless the administrator creates a pre-revprop-change hook
in the repository, this feature will fail.

=item $client-E<gt>status($path, $revision, \&status_func, $recursive, $get_all, $update, $no_ignore, $pool);

Similar to $client-E<gt>status2(), but with ignore_externals always set to FALSE, and with the status_func receiving a svn_wc_status2_t instead of a svn_wc_status_t object.

=item $client-E<gt>status2($path, $revision, \&status_func, $recursive, $get_all, $update, $no_ignore, $ignore_externals, $pool);

Similar to $client-E<gt>status3(), but with the changelists passed as undef, and with recursive instead of depth.

=item $client-E<gt>status3($path, $revision, \&status_func, $depth, $get_all, $update, $no_ignore, $ignore_externals, $changelists, $pool);

Similar to $client-E<gt>status4(), without the pool parameter to the callback and the return of the callback is ignored. 

=item $client-E<gt>status4($path, $revision, \&status_func, $depth, $get_all, $update, $no_ignore, $ignore_externals, $changelists, $pool);

Given $path to a working copy directory (or single file), call status_func()
with a set of svn_wc_status2_t objects which describe the status of $path and
its children.

If $recursive is true, recurse fully, else do only immediate children.

If $get_all is set, retrieve all entries; otherwise, retrieve only 'interesting'
entries (local mods and/or out-of-date).

If $update is set, contact the repository and augment the status objects with
information about out-of-dateness (with respect to $revision).  Also, will
return the value of the actual revision against with the working copy was
compared.  (The return will be undef if $update is not set).

Unless ignore_externals is set, the function recurses into externals definitions
('svn:externals') after handling the main target, if any exist.  The function
calls the notify callback with $SVN::Wc::Notify::Action::status_external action
before handling each externals definition, and with 
$SVN::Wc::Notify::Action::status_completed after each.

$changelists is a reference to an array of changelist names, used as a restrictive filter on items whose statuses are reported; that is don't report status about any item unless it's a member of those changelists.  If changelists is empty (or altogether undef), no changelist filtering occurs.

The status_func subroutine takes the following parameters:
$path, $status, $pool

$path is the pathname of the file or directory which status is being
reported.  $status is a svn_wc_status2_t object.  $pool is an apr_pool_t
object which is cleaned between invocations to the callback.

The return of the status_func subroutine can be a svn_error_t object created by
SVN::Error::create in order to propagate an error up.

=item $client-E<gt>switch($path, $url, $revision, $recursive, $pool);

Switch working tree $path to $url at $revision.

$revision must be a number, 'HEAD', or a date, otherwise it raises the
$SVN::Error::CLIENT_BAD_REVISION error.

Calls the notify callback on paths affected by the switch.  Also invokes
the callback for files that may be restored from the text-base because they
were removed from the working copy.

Summary of purpose: This is normally used to switch a working directory
over to another line of development, such as a branch or a tag.  Switching
an existing working directory is more efficient than checking out $url from
scratch.

Returns the value of the revision to which the working copy was actually
switched.

=item $client-E<gt>update($path, $revision, $recursive, $pool)

Similar to $client-E<gt>update2() except that it accepts only a single target in
$path, returns a single revision, and $ignore_externals is always set to FALSE.

=item $client-E<gt>update2($paths, $revision, $recursive, $ignore_externals, $pool)

Similar to $client-E<gt>update3() but with $allow_unver_obstructions always set to
FALSE, $depth_is_sticky to FALSE, and $depth set according to $recursive: if
$recursive is TRUE, set $depth to $SVN::Depth::infinity, if $recursive is
FALSE, set $depth to $SVN::Depth::files.

=item $client-E<gt>update3($paths, $revision, $depth, $depth_is_sticky, $ignore_externals, $allow_unver_obstructions, $pool)

Similar to $client-E<gt>update4() but with $make_parents always set to FALSE and
$adds_as_modification set to TRUE.

=item $client-E<gt>update4($paths, $revision, $depth, $depth_is_sticky, $ignore_externals, $allow_unver_obstructions, $adds_as_modification, $make_parents)

Update working trees $paths to $revision.

$paths is a array reference of paths to be updated.  Unversioned paths that are
the direct children of a versioned path will cause an update that attempts to
add that path; other unversioned paths are skipped.

$revision must be a revision number, 'HEAD', or a date or this method will
raise the $SVN::Error::CLIENT_BAD_REVISION error.

The paths in $paths can be from multiple working copies from multiple
repositories, but even if they all come from the same repository there is no
guarantee that revision represented by 'HEAD' will remain the same as each path
is updated.

If $ignore_externals is set, don't process externals definitions as part of
this operation.

If $depth is $SVN::Depth::infinity, update fully recursivelly.  Else if it is
$SVN::Depth::immediates or $SVN::Depth::files, update each target and its file
entries, but not its subdirectories.  Else if $SVN::Depth::empty, update
exactly each target, nonrecursively (essentially, update the target's
properties).

If $depth is $SVN::Depth::unknown, take the working depth from $paths and then
describe as behaved above.

If $depth_is_sticky is set and $depth is not $SVN::Depth::unknown, then in
addition to update paths, also set their sticky ambient depth value to $depth.

If $allow_unver_obstructions is TRUE then the update tolerates existing 
unversioned items that obstruct added paths.  Only obstructions of the same
type (file or dir) as the added item are tolerated.  The text of obstructing
files is left as-is, effectively treating it as a user modification after the
update.  Working properties of obstructing items are set equal to the base
properties.  If $allow_unver_obstructions is FALSE then the update will abort
if there are any unversioned obstructing items.

If $adds_as_modification is TRUE, a local addition at the same path as an 
incoming addition of the same node kind results in a normal node with a
possible local modification, instead of a tree conflict.

If $make_parents is TRUE, create any non-existent parent directories also by
checking them out at depth=empty.

Calls the notify callback for each item handled by the update, and
also for files restored from the text-base.

Returns an array reference to an array of revision numbers with each element
set to the revision to which $revision was resolved for the corresponding
element of $paths.


=item $client-E<gt>url_from_path($target, $pool); or SVN::Client::url_from_path($target, $pool);

Returns the URL for $target.

If $target is already a URL it returns $target.

If $target is a versioned item, it returns $target's entry URL.

If $target is unversioned (has no entry), returns undef.

=item $client-E<gt>uuid_from_path($path, $adm_access, $pool);

Return the repository uuid for working-copy $path, allocated in $pool.

Use $adm_access to retrieve the uuid from $path's entry; if not present in the
entry, then call $client-E<gt>uuid_from_url() to retrieve, using the entry's URL.

Note: The only reason this function falls back on $client-E<gt>uuid_from_url is for
compatibility purposes.  Old working copies may not have uuids in the entries
files.

Note: This method probably doesn't work right now without a lot of pain,
because SVN::Wc is incomplete and it requires an adm_access object from it.

=item $client-E<gt>uuid_from_url($url, $pool);

Return repository uuid for url.

=back

=cut

# import methods into our name space and wrap them in a closure
# to support method calling style $client->log()
foreach my $function (@_all_fns)
{
    no strict 'refs';
    my $real_function = \&{"SVN::_Client::svn_client_$function"};
    *{"SVN::Client::$function"} = sub
    {
        my ($self, $ctx);
        my @args;

        # Don't shift the first param if it isn't a SVN::Client
        # object.  This lets the old style interface still work.
        # And is useful for functions like url_from_path which
        # don't take a ctx param, but might be called in method
        # invocation style or as a normal function.
        for (my $index = $[; $index <= $#_; $index++)
        {
            if (ref($_[$index]) eq 'SVN::Client')
            {
                ($self) = splice(@_,$index,1);
                $ctx = $self->{'ctx'};
                last;
            } elsif (ref($_[$index]) eq '_p_svn_client_ctx_t') {
                $self = undef;
                ($ctx) = splice(@_,$index,1);
                last;
            }
        }

        if (!defined($ctx))
        {
            # Allows import to work while not breaking use SVN::Client.
            if ($function eq 'import')
            {
                return;
            }
        }

        if (ref($_[$#_]) eq '_p_apr_pool_t' ||
            ref($_[$#_]) eq 'SVN::Pool')
        {
            # if we got a pool passed to us we need to
            # leave it off until we add the ctx first
            # so we push only the first arg to the next
            # to last arg.
            push @args, @_[$[ .. ($#_ - 1)];
            unless ($function =~ /^(?:propset|url_from_path)$/)
            {
                # propset and url_from_path don't take a ctx argument
                push @args, $ctx;
            }
            push @args, $_[$#_];
        } else {
            push @args, @_;
            unless ($function =~ /^(?:propset|url_from_path)$/)
            {
                push @args,$ctx;
            }
            if (defined($self->{'pool'}) &&
                (ref($self->{'pool'}) eq '_p_apr_pool_t' ||
                 ref($self->{'pool'}) eq 'SVN::Pool'))
            {
                # allow the pool entry in the SVN::Client
                # object to override the default pool.
                push @args, $self->{'pool'};
            }
        }
        return $real_function->(@args);
    }
}

=head1 ATTRIBUTE METHODS

The following attribute methods are provided that allow you to set various
configuration or retrieve it.  They all take value(s) to set the attribute and
return the new value of the attribute or no parameters which returns the
current value.

=over 4

=item $client-E<gt>auth(SVN::Client::get_username_provider());

Provides access to the auth_baton in the svn_client_ctx_t attached to the
SVN::Client object.

This method will accept an array or array ref of values returned from the
authentication provider functions see L</"AUTHENTICATION PROVIDERS">, which
it will convert to an auth_baton for you.  This is the preferred method of
setting the auth_baton.

It will also accept a scalar that references a _p_svn_auth_baton_t such as
those returned from SVN::Core::auth_open and SVN::Core::auth_open_helper.

=cut

sub auth
{
    my $self = shift;
    my $args;
    if (scalar(@_) == 0)
    {
        return $self->{'ctx'}->auth_baton();
    } elsif (scalar(@_) > 1) {
        $args = \@_;
    } else {
        $args = shift;
        if (ref($args) eq '_p_svn_auth_baton_t')
        {
            # 1 arg as an auth_baton so just set
            # the baton.
            $self->{'ctx'}->auth_baton($args);
            return $self->{'ctx'}->auth_baton();
        }
    }

    my ($auth_baton,$callbacks) = SVN::Core::auth_open_helper($args);
    $self->{'auth_provider_callbacks'} = $callbacks;
    $self->{'ctx'}->auth_baton($auth_baton);
    return $self->{'ctx'}->auth_baton();
}

=item $client-E<gt>notify(\&notify);

Sets the notify callback for the client context to a code reference that
you pass.  It always returns the current codereference set.

The subroutine pointed to by this reference will be called when a change
is made to the working copy.  The return value of this function is ignored.
It's only purpose is to notify you of the change.

The subroutine will receive 6 parameters.  The first parameter will be the path
of the changed file (absolute or relative to the cwd).  The second is an
integer specifying the type of action taken.  See L<SVN::Wc> for a list of the
possible actions values and what they mean.  The 3rd is an integer specifying
the kind of node the path is, which can be: $SVN::Node::none, $SVN::Node::file,
$SVN::Node::dir, $SVN::Node::unknown.  The fourth parameter is the mime-type of
the file or undef if the mime-type is unknown (it will always be undef for
directories).  The 5th parameter is the state of the file, again see L<SVN::Wc>
for a list of the possible states.  The 6th and final parameter is the numeric
revision number of the changed file.  The revision number will be -1 except
when the action is $SVN::Wc::Notify::Action::update_completed.

=cut

sub notify {
    my $self = shift;
    if (scalar(@_) == 1) {
        $self->{'notify_callback'} = $self->{'ctx'}->notify_baton(shift);
    }
    return ${$self->{'notify_callback'}};
}

=item $client-E<gt>log_msg(\&log_msg)

Sets the log_msg callback for the client context to a code reference that you
pass.  It always returns the current codereference set.

The subroutine pointed to by this coderef will be called to get the log
message for any operation that will commit a revision to the repo.

It receives 4 parameters.  The first parameter is a reference to a scalar
value in which the callback should place the log_msg.  If you wish to cancel
the commit you can set this scalar to undef.  The 2nd value is a path to any
temporary file which might be holding that log message, or undef if no such
file exists (though, if log_msg is undef, this value is undefined).  The
log message B<MUST> be a UTF8 string with LF line separators.  The 3rd parameter
is a reference to an array of svn_client_commit_item3_t objects, which may
be fully or only partially filled-in, depending on the type of commit
operation.  The 4th and last parameter will be a pool.

If the function wishes to return an error it should return a svn_error_t
object made with SVN::Error::create.  Any other return value will be
interpreted as SVN_NO_ERROR.

=cut

sub log_msg {
    my $self = shift;

    if (scalar(@_) == 1) {
        $self->{'log_msg_callback'} = $self->{'ctx'}->log_msg_baton3(shift);
    }
    return ${$self->{'log_msg_callback'}};
}

=item $client-E<gt>cancel(\&cancel)

Sets the cancellation callback for the client context to a code reference that you
pass. See L<"CANCELLATION CALLBACK"> below for details.
It always returns the current codereference set.

=cut

sub cancel {
    my $self = shift;

    if (scalar(@_) == 1) {
        $self->{'cancel_callback'} = $self->{'ctx'}->cancel_baton(shift);
    }
    return ${$self->{'cancel_callback'}};
}

=item $client-E<gt>pool(new SVN::Pool);

Method that sets or gets the default pool that is passed to method calls
requiring a pool, but which were not explicitly passed one.

See L<SVN::Core> for more information about how pools are managed
in this interface.

=cut

sub pool
{
    my $self = shift;

    if (scalar(@_) == 0)
    {
        $self->{'pool'};
    } else {
        return $self->{'pool'} = shift;
    }
}
=item $client-E<gt>config(SVN::Core::config_get_config(undef));

Method that allows access to the config member of the svn_client_ctx_t.
Accepts a Perl hash to set, which is what functions like
SVN::Core:config_get_config() will return.

It will return a _p_arp_hash_t scalar.  This is a temporary
situation.  The return value is not particular useful.  In
the future, this value will be tied to the actual hash used
by the C API.

=back

=cut

sub config
{
    my $self = shift;
    if (scalar(@_) == 0) {
        return $self->{'ctx'}->config();
    } else {
        $self->{'ctx'}->config(shift);
        return $self->{'ctx'}->config();
    }
}


=head1 AUTHENTICATION PROVIDERS

The following functions get authentication providers for you.
They come in two forms.  Standard or File versions, which look
for authentication information in the subversion configuration
directory that was previously cached, or Prompt versions which
call a subroutine to allow you to prompt the user for the
information.

The functions that return the svn_auth_provider_object_t for prompt style
providers take a reference to a Perl subroutine to use for the callback.  The
first parameter each of these subroutines receive is a credential object.  The
subroutines return the response by setting members of that object.  Members may
be set like so: $cred-E<gt>username("breser");  These functions and credential
objects always have a may_save member which specifies if the authentication
data will be cached.

The providers are as follows:

        NAME                WHAT IT HANDLES
        ----------------    ----------------------------------------
        simple              username and password pairs

        username            username only

        ssl_server_trust    server certificates and failures
                            authenticating them

        ssl_client_cert     client side certificate files

        ssl_client_cert_pw  password for a client side certificate file.


=over 4

=item SVN::Client::get_simple_provider

Returns a simple provider that returns information from previously cached
sessions.  Takes no parameters or one pool parameter.

=item SVN::Client::get_simple_prompt_provider

Returns a simple provider that prompts the user via a callback.  Takes two or
three parameters, the first is the callback subroutine, the 2nd is the number
of retries to allow, the 3rd is optionally a pool.  The subroutine gets called
with the following parameters: a svn_auth_cred_simple_t object, a realm string,
a default username, may_save, and a pool.  The svn_auth_cred_simple has the
following members: username, password, and may_save.

=item SVN::Client::get_username_provider

Returns a username provider that returns information from a previously cached
sessions.  Takes no parameters or one pool parameter.

=item SVN::Client::get_username_prompt_provider

Returns a username provider that prompts the user via a callback.  Takes two or
three parameters, the first is the callback subroutine, the 2nd is the number
of retries to allow, the 3rd is optionally a pool.  The subroutine gets called
with the following parameters: a svn_auth_cred_username_t object, a realm
string, a default username, may_save, and a pool.  The svn_auth_cred_username
has the following members: username and may_save.

=item SVN::Client::get_ssl_server_trust_file_provider

Returns a server trust provider that returns information from previously
cached sessions.  Takes no parameters or optionally a pool parameter.

=item SVN::Client::get_ssl_server_trust_prompt_provider

Returns a server trust  provider that prompts the user via a callback. Takes
one or two parameters the callback subroutine and optionally a pool parameter.
The subroutine gets called with the following parameters.  A
svn_auth_cred_ssl_server_trust_t object, a realm string, an integer specifying
how the certificate failed authentication, a svn_auth_ssl_server_cert_info_t
object, may_save, and a pool.  The svn_auth_cred_ssl_server_trust_t object has
the following members: may_save and accepted_failures.  The
svn_auth_ssl_server_cert_info_t object has the following members (and behaves
just like cred objects though you can't modify it): hostname, fingerprint,
valid_from, valid_until, issuer_dname, ascii_cert.

The masks used for determining the failures are in SVN::Auth::SSL and are named:

$SVN::Auth::SSL::NOTYETVALID
$SVN::Auth::SSL::EXPIRED
$SVN::Auth::SSL::CNMISMATCH
$SVN::Auth::SSL::UNKNOWNCA
$SVN::Auth::SSL::OTHER

You reply by setting the accepted_failures of the cred object with an integer
of the values for what you want to accept bitwise AND'd together.

=item SVN::Client::get_ssl_client_cert_file_provider

Returns a client certificate provider that returns information from previously
cached sessions.  Takes no parameters or optionally a pool parameter.

=item SVN::Client::get_ssl_client_cert_prompt_provider

Returns a client certificate provider that prompts the user via a callback.
Takes two or three parameters: the first is the callback subroutine, the 2nd is
the number of retries to allow, the 3rd is optionally a pool parameter.  The
subroutine gets called with the following parameters.  A
svn_auth_cred_ssl_client_cert object, a realm string, may_save, and a pool.
The svn_auth_cred_ssl_client_cert the following members: cert_file and
may_save.

=item SVN::Client::get_ssl_client_cert_pw_file_provider

Returns a client certificate password provider that returns information from
previously cached sessions.  Takes no parameters or optionally a pool
parameter.

=item SVN::Client::get_ssl_client_cert_pw_prompt_provider

Returns a client certificate password provider that prompts the user via a
callback. Takes two or three parameters, the first is the callback subroutine,
the 2nd is the number of retries to allow, the 3rd is optionally a pool
parameter.  The subroutine gets called with the following parameters.  A
svn_auth_cred_ssl_client_cert_pw object, a realm string, may_save, and a pool.
The svn_auth_cred_ssl_client_cert_pw has the following members: password and
may_save.

=back

=head1 CANCELLATION CALLBACK

This callback will be called periodically to see if the operation
should be canceled.  If the operation should be canceled, the function may
return one of the following values:

An svn_error_t object made with SVN::Error::create.

Any true value, in which case the bindings will generate an svn_error_t object
for you with the error code of SVN_ERR_CANCELLED and the string set to "By
cancel callback".

A string, in which case the bindings will generate an svn_error_t object for you
with the error code of SVN_ERR_CANCELLED and the string set to the string you
returned.

Any other value will be interpreted as wanting to continue the operation.
Generally, it's best to return 0 to continue the operation.

=head1 OBJECTS

These are some of the object types that are returned from the methods
and functions.  Others are documented in L<SVN::Core> and L<SVN::Wc>.
If an object is not documented, it is more than likely opaque and
not something you can do anything with, except pass to other functions
that require such objects.

=cut

package _p_svn_info_t;
use SVN::Base qw(Client svn_info_t_);

=head2 svn_info_t

=over 8

=item $info-E<gt>URL()

Where the item lives in the repository.

=item $info-E<gt>rev()

The revision of the object.  If path_or_url is a working-copy
path, then this is its current working revnum.  If path_or_url
is a URL, then this is the repos revision that path_or_url lives in.

=item $info-E<gt>kind()

The node's kind.

=item $info-E<gt>repos_root_URL()

The root URL of the repository.

=item $info-E<gt>repos_UUID()

The repository's UUID.

=item $info-E<gt>last_changed_rev()

The last revision in which this object changed.

=item $info-E<gt>last_changed_date()

The date of the last_changed_rev.

=item $info-E<gt>last_changed_author()

The author of the last_changed_rev.

=item $info-E<gt>lock()

An exclusive lock, if present.  Could be either local or remote.

=back

See SVN::Wc::svn_wc_entry_t for the rest of these.   svn_client.h indicates
that these were copied from that struct and mean the same things.   They are
also only useful when working with a WC.

=over 8

=item $info-E<gt>has_wc_info()

=item $info-E<gt>schedule()

=item $info-E<gt>copyfrom_url()

=item $info-E<gt>copyfrom_rev()

=item $info-E<gt>text_time()

=item $info-E<gt>prop_time()

=item $info-E<gt>checksum()

=item $info-E<gt>conflict_old()

=item $info-E<gt>conflict_new()

=item $info-E<gt>conflict_wrk()

=item $info-E<gt>prejfile()

=back

=cut

package _p_svn_client_commit_info_t;
use SVN::Base qw(Client svn_client_commit_info_t_);

=head2 svn_client_commit_item3_t

=over 8

=item $commit_item-E<gt>path()

Absolute working-copy path of item.

=item $commit_item-E<gt>kind()

An integer representing the type of node it is (file/dir).
Can be one of the following constants:
$SVN::Node::none
$SVN::Node::file
$SVN::Node::dir
$SVN::Node::unknown

=item $commit_item-E<gt>url()

Commit URL for this item.

=item $commit_item-E<gt>revision()

Revision (copyfrom_rev if state_flags has IS_COPY set).

=item $commit_item-E<gt>copyform_url();

CopyFrom URL

=item $commit_item-E<gt>state_flags();

One of several state flags:
$SVN::Client::COMMIT_ITEM_ADD
$SVN::Client::COMMIT_ITEM_DELETE
$SVN::Client::COMMIT_ITEM_TEXT_MODS
$SVN::Client::COMMIT_ITEM_PROP_MODS
$SVN::Client::COMMIT_ITEM_IS_COPY

=item $commit_item-E<gt>incoming_prop_changes()

A reference to an array of svn_prop_t objects representing changes to
WC properties.

=item $commit_item-E<gt>outgoing_prop_changes()

A reference to an array of svn_prop_t objects representing extra
changes to properties in the repository (which are not necessarily
reflected by the WC).

=back

=cut

package _p_svn_client_commit_item3_t;
use SVN::Base qw(Client svn_client_commit_item3_t_);

=head2 svn_client_commit_info_t

=over 4

=item $commit_info-E<gt>revision()

Just committed revision.

=item $commit_info-E<gt>date()

Server-Side date of the commit as a string.

=item $commit_info-E<gt>author()

Author of the commit.

=back

=cut

package _p_svn_client_ctx_t;
use SVN::Base qw(Client svn_client_ctx_t_);

package _p_svn_client_proplist_item_t;
use SVN::Base qw(Client svn_client_proplist_item_t_);

=head2 svn_client_proplist_item_t

=over 8

=item $proplist-E<gt>node_name()

The name of the node on which these properties are set.

=item $proplist-E<gt>prop_hash()

A reference to a hash of property names and values.

=back

=cut

package SVN::Client::Summarize;
use SVN::Base qw(Client svn_client_diff_summarize_kind_);

=head2 svn_client_diff_summarize_kind_t - SVN::Summarize

An enum of the following constants:

$SVN::Client::Summarize::normal, $SVN::Client::Summarize::added,
$SVN::Client::Summarize::modified, $SVN::Client::Summarize::deleted.

=cut

package _p_svn_client_diff_summarize_t;
use SVN::Base qw(Client svn_client_diff_summarize_t_);

=head2 svn_client_diff_summarize_t

=over 8

=item $diff_summarize-E<gt>path()

Path relative to the target.  If the target is a file, path is the
empty string.

=item $diff_summarize-E<gt>summarize_kind()

Change kind.

=item $diff_summarize-E<gt>prop_changed()

Properties changed?

=item $diff_summarize-E<gt>node_kind()

File or dir?

=back

=head2 ADDITIONAL METHODS

The following methods work, but are not currently documented in this
file.  Please consult the svn_client.h section in the Subversion API
for more details.

=over 4

=item $client-E<gt>add_to_changelist(...)

=item $client-E<gt>blame2(...)

=item $client-E<gt>blame3(...)

=item $client-E<gt>blame4(...)

=item $client-E<gt>cat2(...)

=item $client-E<gt>commit2(...)

=item $client-E<gt>commit3(...)

=item $client-E<gt>commit4(...)

=item $client-E<gt>copy2(...)

=item $client-E<gt>copy3(...)

=item $client-E<gt>copy4(...)

=item $client-E<gt>create_context(...)

=item $client-E<gt>delete2(...)

=item $client-E<gt>delete3(...)

=item $client-E<gt>diff2(...)

=item $client-E<gt>diff3(...)

=item $client-E<gt>diff4(...)

=item $client-E<gt>diff_peg(...)

=item $client-E<gt>diff_peg2(...)

=item $client-E<gt>diff_peg3(...)

=item $client-E<gt>diff_peg4(...)

=item $client-E<gt>diff_summarize2(...)

=item $client-E<gt>diff_summarize_dup(...)

=item $client-E<gt>diff_summarize_peg(...)

=item $client-E<gt>diff_summarize_peg2(...)

=item $client-E<gt>export2(...)

=item $client-E<gt>export3(...)

=item $client-E<gt>export4(...)

=item $client-E<gt>import2(...)

=item $client-E<gt>import3(...)

=item $client-E<gt>info2(...)

=item $client-E<gt>invoke_blame_receiver(...)

=item $client-E<gt>invoke_blame_receiver2(...)

=item $client-E<gt>invoke_diff_summarize_func(...)

=item $client-E<gt>list(...)

=item $client-E<gt>list2(...)

=item $client-E<gt>ls2(...)

=item $client-E<gt>ls3(...)

=item $client-E<gt>merge2(...)

=item $client-E<gt>merge3(...)

=item $client-E<gt>merge_peg(...)

=item $client-E<gt>merge_peg2(...)

=item $client-E<gt>merge_peg3(...)

=item $client-E<gt>move2(...)

=item $client-E<gt>move3(...)

=item $client-E<gt>move4(...)

=item $client-E<gt>move5(...)

=item $client-E<gt>open_ra_session(...)

=item $client-E<gt>propget2(...)

=item $client-E<gt>propget3(...)

=item $client-E<gt>proplist2(...)

=item $client-E<gt>proplist3(...)

=item $client-E<gt>propset2(...)

=item $client-E<gt>propset3(...)

=item $client-E<gt>remove_from_changelist(...)

=item $client-E<gt>resolve(...)

=item $client-E<gt>revert2(...)

=item $client-E<gt>switch2(...)

=item $client-E<gt>unlock(...)

=item $client-E<gt>version(...)

=back

=head1 TODO

* Better support for the config.

* Unit tests for cleanup, diff, export, merge, move, relocate, resolved
and switch.  This may reveal problems for using these methods as I haven't
tested them yet that require deeper fixes.

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

Ben Reser E<lt>ben@reser.orgE<gt>

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
