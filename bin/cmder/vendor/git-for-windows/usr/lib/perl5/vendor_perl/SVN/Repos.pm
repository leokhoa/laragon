use strict;
use warnings;

package SVN::Repos;
use SVN::Base qw(Repos svn_repos_);

=head1 NAME

SVN::Repos - Subversion repository functions

=head1 SYNOPSIS

    use SVN::Core;
    use SVN::Repos;
    use SVN::Fs;

    my $repos = SVN::Repos::open('/path/to/repos');
    print $repos->fs()->youngest_rev;

=head1 DESCRIPTION

SVN::Repos wraps the object-oriented C<svn_repos_t> functions, providing
access to a Subversion repository on the local filesystem.

=head2 CONSTRUCTORS

=over

=item SVN::Repos::open($path)

This function opens an existing repository, and returns an
C<SVN::Repos> object.

=item create($path, undef, undef, $config, $fs_config)

This function creates a new repository, and returns an C<SVN::Repos>
object.

=back

=head2 METHODS

=over

=item $repos-E<gt>dump_fs($dump_fh, $feedback_fh, $start_rev, $end_rev, $incremental, $cancel_callback)

=item $repos-E<gt>dump_fs2($dump_fh, $feedback_fh, $start_rev, $end_rev, $incremental, $deltify, $cancel_callback)

Create a dump file of the repository from revision C<$start_rev> to C<$end_rev>
, store it into the filehandle C<$dump_fh>, and write feedback on the progress
of the operation to filehandle C<$feedback_fh>.

If C<$incremental> is TRUE, the first revision dumped will be a diff
against the previous revision (usually it looks like a full dump of
the tree).

If C<$use_deltas> is TRUE, output only node properties which have
changed relative to the previous contents, and output text contents
as svndiff data against the previous contents.  Regardless of how
this flag is set, the first revision of a non-incremental dump will
be done with full plain text.  A dump with @a use_deltas set cannot
be loaded by Subversion 1.0.x.

If C<$cancel_callback> is not C<undef>, it must be a code reference
that is called periodically to determine whether the client wishes 
to cancel the dump.  See L<SVN::Client/"CANCELLATION CALLBACK"> for details.

Example:

    use SVN::Core;
    use SVN::Repos;

    my $repos = SVN::Repos::open('/repo/sandbox');

    open my $fh, ">/tmp/tmp.dump" or die "Cannot open file: $!\n";

    my $start_rev   = 10;
    my $end_rev     = 20;
    my $incremental = 1;
    my $deltify     = 1;

    $repos->dump_fs2($fh, \*STDOUT,          # Dump file => $fh, Feedback => STDOUT
                     $start_rev, $end_rev,   # Revision Range
                     $incremental, $deltify, # Options
                     undef);                 # Cancel Callback

    close $fh;

=item $repos-E<gt>load_fs($dumpfile_fh, $feedback_fh, $uuid_action, $parent_dir, $cancel_callback);

=item $repos-E<gt>load_fs2($dumpfile_fh, $feedback_fh, $uuid_action, $parent_dir, $use_pre_commit_hook, $use_post_commit_hook, $cancel_callback);

Loads a dumpfile specified by the C<$dumpfile_fh> filehandle into the repository.
If the dumpstream contains copy history that is unavailable in the repository,
an error will be thrown.

The repository's UUID will be updated iff the dumpstream contains a UUID and
C<$uuid_action> is not equal to C<$SVN::Repos::load_uuid_ignore> and either the
repository contains no revisions or C<$uuid_action> is equal to
C<$SVN::Repos::load_uuid_force>.

If the dumpstream contains no UUID, then C<$uuid_action> is
ignored and the repository UUID is not touched.

If C<$parent_dir> is not null, then the parser will reparent all the
loaded nodes, from root to @a parent_dir.  The directory C<$parent_dir>
must be an existing directory in the repository.

If C<$use_pre_commit_hook> is set, call the repository's pre-commit
hook before committing each loaded revision.

If C<$use_post_commit_hook> is set, call the repository's
post-commit hook after committing each loaded revision.

If C<$cancel_callback> is not C<undef>, it must be a code reference 
that is called periodically to determine whether the client wishes
to cancel the load.  See L<SVN::Client/"CANCELLATION CALLBACK"> for details.

You must at least provide C<undef> for these parameters for the method call
to work.

Example:
    use SVN::Core;
    use SVN::Repos;

    my $repos = SVN::Repos::open('/repo/test_repo');

    open my $fh, "/repo/sandbox.dump" or die "Cannot open file: $!\n";

    my $parent_dir = '/';
    my $use_pre_commit_hook  = 0;
    my $use_post_commit_hook = 0;

    $repos->load_fs2($fh, \*STDOUT,
                     $SVN::Repos::load_uuid_ignore, # Ignore uuid
                     $parent_dir,
                     $use_pre_commit_hook,  # Use pre-commit hook?
                     $use_post_commit_hook, # Use post-commit hook?
                     undef, undef);


    close $fh;

=cut

# Build up a list of methods as we go through the file.  Add each method
# to @methods, then document it.  The full list of methods is then
# instantiated at the bottom of this file.
#
# This should make it easier to keep the documentation and list of methods
# in sync.

my @methods = (); # List of methods to wrap

push @methods, qw(fs);

=item $repos-E<gt>fs()

Returns the C<SVN::Fs> object for this repository.

=cut

push @methods, qw(get_logs);

=item $repos-E<gt>get_logs([$path, ...], $start, $end, $discover_changed_paths, $strict_node_history, $receiver)

Iterates over all the revisions that affect the list of paths passed
as the first parameter, starting at $start, and ending at $end.

$receiver is called for each change.  The arguments to $receiver are:

=over

=item $self

The C<SVN::Repos> object.

=item $paths

C<undef> if $discover_changed_paths is false.  Otherwise, contains a hash
of paths that have changed in this revision.

=item $rev

The revision this change occurred in.

=item $date

The date and time the revision occurred.

=item $msg

The log message associated with this revision.

=item $pool

An C<SVN::Pool> object which may be used in the function.

=back

If $strict_node_history is true then copies will not be traversed.

=back

=head2 ADDITIONAL METHODS

The following methods work, but are not currently documented in this
file.  Please consult the svn_repos.h section in the Subversion API
for more details.

=over

=item $repos-E<gt>get_commit_editor(...)

=item $repos-E<gt>get_commit_editor2(...)

=item $repos-E<gt>path(...)

=item $repos-E<gt>db_env(...)

=item $repos-E<gt>lock_dir(...)

=item $repos-E<gt>db_lockfile(...)

=item $repos-E<gt>hook_dir(...)

=item $repos-E<gt>start_commit_hook(...)

=item $repos-E<gt>pre_commit_hook(...)

=item $repos-E<gt>post_commit_hook(...)

=item $repos-E<gt>pre_revprop_change(...)

=item $repos-E<gt>post_revprop_change(...)

=item $repos-E<gt>dated_revision(...)

=item $repos-E<gt>fs_commit_txn(...)

=item $repos-E<gt>fs_being_txn_for_commit(...)

=item $repos-E<gt>fs_being_txn_for_update(...)

=item $repos-E<gt>fs_change_rev_prop(...)

=item $repos-E<gt>node_editor(...)

=item $repos-E<gt>dump_fs(...)

=item $repos-E<gt>load_fs(...)

=item $repos-E<gt>get_fs_build_parser(...)

=back

=cut

push @methods,
     qw( version open create delete hotcopy recover3 recover2
         recover db_logfiles path db_env conf_dir svnserve_conf
         get_commit_editor get_commit_editor2 fs_commit_txn
         lock_dir db_lockfile db_logs_lockfile hook_dir
         pre_revprop_change_hook pre_lock_hook pre_unlock_hook
         begin_report2 begin_report link_path3 link_path2 link_path
         delete_path finish_report dir_delta2 dir_delta replay2 replay
         dated_revision stat deleted_rev history2 history
         trace_node_locations fs_begin_txn_for_commit2
         fs_begin_txn_for_commit fs_begin_txn_for_update fs_lock
         fs_unlock fs_change_rev_prop3 fs_change_rev_prop2
         fs_change_rev_prop fs_revision_prop fs_revision_proplist
         fs_change_node_prop fs_change_txn_prop node_editor
         node_from_baton dump_fs2 dump_fs load_fs2 load_fs
         authz_check_access check_revision_access invoke_authz_func
         invoke_authz_callback invoke_file_rev_handler
         invoke_history_func);

{
    no strict 'refs';
    for (@methods) {
        *{"_p_svn_repos_t::$_"} = *{$_};
    }
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
