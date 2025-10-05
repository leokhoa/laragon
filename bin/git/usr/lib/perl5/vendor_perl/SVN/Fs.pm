use strict;
use warnings;

package SVN::Fs;
use SVN::Base qw(Fs svn_fs_);

=head1 NAME

SVN::Fs - Subversion filesystem functions

=head1 DESCRIPTION

SVN::Fs wraps the functions in svn_fs.h.  The actual namespace
for filesystem objects is C<_p_svn_fs_t>.

=head1 FUNCTIONS

=over

=item SVN::Fs::berkeley_logfiles($path, $only_unused)

=item SVN::Fs::berkeley_recover($path)

=item SVN::Fs::check_related($id1, $id2)

=item SVN::Fs::compare_ids($id1, $id2)

=item SVN::Fs::contents_changed($root1, $path1, $root2, $path2)

=item SVN::Fs::create($path, $config)

=item SVN::Fs::delete_fs($path)

=item SVN::Fs::deltify_revision($fs, $rev)

=item SVN::Fs::get_file_delta_stream($source_root, $source_path, $target_root, $target_path)

=item SVN::Fs::hotcopy($src_path, $dest_path, $clean)

=item SVN::Fs::initialize($pool)

=item SVN::Fs::merge($source_root, $source_path, $target_root, $target_path, $ancestor_root, $ancestor_path)

=item SVN::Fs::open($path, $config)

=item SVN::Fs::path($fs)

=item SVN::Fs::print_modules($s)

TODO - doesn't work, segfaults if $s is null, doesn't do anything if
its an empty string

=item SVN::Fs::props_changed($root1, $path1, $root2, $path2)

See also C<SVN::Fs::contents_changed>

=item SVN::Fs::purge_txn($fs, $txn_id)

Cleanup the transaction C<$txn_id>, removing it completely from
the filesystem C<$fs>.

=item SVN::Fs::set_warning_func($fs, $code, $baton)

=item SVN::Fs::unparse_id($id)

Return a string containing the unparsed form of the node or node
revision id $id, which must be a C<_p_svn_fs_id_t> object.

TODO - why isn't this a method of that object?

=item SVN::Fs::version()

TODO - what can we do with the _p_svn_version_t value returned?

=item SVN::Fs::create_access($username)

Return a new C<_p_svn_fs_access_t> object representing C<$username>.
C<$username> is presumed to have been authenticated by the caller.

=back

=cut

package _p_svn_fs_t;

=head1 _p_svn_fs_t

=over

=item $fs-E<gt>begin_txn($rev)

Creates a new transaction in the repository, and returns a
C<_p_svn_fs_txn_t> object representing it.  The new transaction's
base revision will be $rev, which should be a number.

=item $fs-E<gt>change_rev_prop

=item $fs-E<gt>generate_lock_token()

Generate a unique lock-token using C<$fs>.

TODO - translate this to apply to Perl:
This can be used in to populate lock-E<gt>token before calling
svn_fs_attach_lock().

=item $fs-E<gt>get_access()

The filesystem's current access context, as a C<_p_svn_fs_access_t>
object.  Returns undef if no access context has been set with
the C<set_access()> method.

=item $fs-E<gt>get_lock

=item $fs-E<gt>get_locks

=item $fs-E<gt>get_uuid()

The UUID associated with C<$fs>.

=item $fs-E<gt>list_transactions()

A reference to an array of all currently active transactions in the
filesystem.  Each one is a string containing the transaction's ID,
suitable for passing to C<$fs-E<gt>open_txn()>.

=item $fs-E<gt>lock

=item $fs-E<gt>open_txn($name)

Get a transaction in the repository by name.  Returns a
C<_p_svn_fs_txn_t> object.

=item $fs-E<gt>revision_prop($rev, $propname)

The value of revision property C<$propname> in revision C<$rev>.

=item $fs-E<gt>revision_proplist($rev)

A hashref containing the names and values of all revision properties
from revision C<$rev>.

=item $fs-E<gt>revision_root

=item $fs-E<gt>set_access($access)

Associate an access context with an open filesystem.

This method can be run multiple times on the same open
filesystem, in order to change the filesystem access context for
different filesystem operations.  C<$access> should be
a C<_p_svn_fs_access_t> object, or undef to disassociate the
current access context from the filesystem.

=item $fs-E<gt>set_uuid($uuid)

Associate C<$uuid> with C<$fs>.

=item $fs-E<gt>unlock

=item $fs-E<gt>youngest_rev()

Return the number of the youngest revision in the filesystem.
The oldest revision in any filesystem is numbered zero.

=back

=cut

our @methods = qw/ youngest_rev revision_root revision_prop revision_proplist
                   change_rev_prop list_transactions open_txn begin_txn
                   get_uuid set_uuid set_access get_access
                   lock unlock get_lock get_locks generate_lock_token path /;

for (@methods) {
    no strict 'refs';
    *{$_} = *{"SVN::Fs::$_"};
}

package _p_svn_fs_root_t;

=head1 _p_svn_fs_root_t

=over

=item $root-E<gt>apply_text

=item $root-E<gt>apply_textdelta

=item $root-E<gt>change_node_prop($path, $propname, $value)

=item $root-E<gt>check_path($path)

Kind of node at C<$path>.  A number which matches one of these constants:
$SVN::Node::none, $SVN::Node::file,
$SVN::Node::dir, $SVN::Node::unknown.

=item $root-E<gt>close_root

=item $root-E<gt>closest_copy

=item $root-E<gt>copied_from

=item $root-E<gt>copy

=item $root-E<gt>delete

=item $root-E<gt>dir_entries

=item $root-E<gt>file_contents

=item $root-E<gt>file_length

=item $root-E<gt>file_md5_checksum

=item $root-E<gt>fs()

The filesystem to which C<$root> belongs, as a C<_p_svn_fs_t> object.

=item $root-E<gt>is_dir($path)

True if there is a node at C<$path> which is a directory.

=item $root-E<gt>is_file($path)

True if there is a node at C<$path> which is a file.

=item $root-E<gt>is_revision_root()

True if the root comes from a revision (i.e., the contents has already been
committed).

=item $root-E<gt>is_txn_root()

True if the root comes from a transaction.

=item $root-E<gt>make_dir

=item $root-E<gt>make_file

=item $root-E<gt>node_created_path($path)

=item $root-E<gt>node_created_rev($path)

=item $root-E<gt>node_history($path)

TODO - _p_svn_fs_history_t

=item $root-E<gt>node_id($path)

=item $root-E<gt>node_prop($path, $propname)

=item $root-E<gt>node_proplist($path)

=item $root-E<gt>paths_changed()

A reference to a hash indicating what changes are made in the root.
The keys are the paths of the files changed, starting with C</> to
indicate the top-level directory of the repository.  The values
are C<_p_svn_fs_path_change_t> objects which contain information about
what kind of changes are made.

=item $root-E<gt>revision_link

=item $root-E<gt>revision_root_revision

Revision number of the revision the root comes from.
For transaction roots, returns C<$SVN::Core::INVALID_REVNUM>.

=back

=cut

our @methods = qw/ apply_textdelta apply_text change_node_prop
                   check_path close_root copied_from copy
                   dir_entries delete file_contents closest_copy
                   file_length file_md5_checksum is_dir is_file
                   is_revision_root is_txn_root make_dir make_file
                   node_created_rev node_history node_id node_prop
                   node_proplist paths_changed revision_link
                   revision_root_revision /;

*fs = *SVN::Fs::root_fs;
*txn_name = *_p_svn_fs_txn_t::root_name;

for (@methods) {
    no strict 'refs';
    *{$_} = *{"SVN::Fs::$_"};
}

package _p_svn_fs_history_t;
use SVN::Base qw(Fs svn_fs_history_);

=head1 _p_svn_fs_history_t

=over

=item $history-E<gt>location()

In list context, a list of two items: the path to the node whose history
this is, and the revision number in which it exists.  In scalar context
returns only the revision number.

=item $history-E<gt>prev($cross_copies)

=back

=cut

package _p_svn_fs_txn_t;
use SVN::Base qw(Fs svn_fs_txn_);

=head1 _p_svn_fs_txn_t

=over

=item $txn-E<gt>abort()

Abort the transaction.  Any changes made in C<$txn> are discarded, and
the filesystem is left unchanged.

Note: This function first sets the state of C<$txn> to 'dead', and
then attempts to purge it and any related data from the filesystem.
If some part of the cleanup process fails, C<$txn> and some portion
of its data may remain in the database after this function returns.
Use C<$fs-E<gt>purge_txn()> to retry the transaction cleanup.

=item $txn-E<gt>base_revision()

The transaction's base revision number.

=item $txn-E<gt>change_prop($name, $value)

Add, change, or remove a property from the transaction.
If C<$value> is C<undef> then the property C<$name> is removed,
if it exists.  Otherwise the property C<$name> is set to the
new value.

=item $txn-E<gt>commit

=item $txn-E<gt>name()

Full name of the revision, in the same format as can be passed
to C<$fs-E<gt>open_txn()>.

=item $txn-E<gt>prop($name)

The value of the transaction's C<$name> property.

=item $txn-E<gt>proplist()

A reference to a hash containing all the transaction's properties,
keyed by name.

=item $txn-E<gt>root()

The root directory of the transaction, as a C<_p_svn_fs_root_t> object.

=back

=cut

*commit = *SVN::Fs::commit_txn;
*abort = *SVN::Fs::abort_txn;
*change_prop = *SVN::Fs::change_txn_prop;

package _p_svn_fs_access_t;
use SVN::Base qw(Fs svn_fs_access_);

=head1 _p_svn_fs_access_t

=head2 SYNOPSIS

    my $access = SVN::Fs::create_access($username);

    my $access = $fs->get_access;
    $fs->set_access($access);

    my $username = $access->get_username;

    $access->add_lock_token($token);

=head2 METHODS

=over

=item $access-E<gt>add_lock_token($token)

Push a lock-token into the access context.  The
context remembers all tokens it receives, and makes them available
to fs functions.

=item $access-E<gt>get_username

The username represented by the access context.

=back

=cut

package _p_svn_fs_dirent_t;
use SVN::Base qw(Fs svn_fs_dirent_t_);

=head1 svn_fs_dirent_t

An object representing a directory entry.  Values of this type are returned
as the values in the hash returned by C<$root-E<gt>dir_entries()>.  They
are like L<svn_dirent_t|SVN::Core/svn_dirent_t> objects, but have less
information.

=over

=item $dirent-E<gt>id()

TODO

=item $dirent-E<gt>kind()

Node kind.  A number which matches one of these constants:
$SVN::Node::none, $SVN::Node::file,
$SVN::Node::dir, $SVN::Node::unknown.

=item $dirent-E<gt>name()

The filename of the directory entry.

=back

=cut

package _p_svn_fs_path_change_t;
use SVN::Base qw(Fs svn_fs_path_change_t_);

=head1 _p_svn_fs_path_change_t

=over

=item $change-E<gt>change_kind()

The type of change made.  A number which matches one of the following:

=over

=item $SVN::Fs::PathChange::modify

Content at path modified.

=item $SVN::Fs::PathChange::add

Path added in transaction.

=item $SVN::Fs::PathChange::delete

Path removed in transaction.

=item $SVN::Fs::PathChange::replace

Path removed and re-added in transaction.

=item $SVN::Fs::PathChange::reset

Ignore all previous change items for path (internal-use only).

=back

=item $change-E<gt>node_rev_id()

Node revision id of changed path.  A C<_p_svn_fs_id_t> object.

=item $change-E<gt>prop_mod()

True if the properties were modified.

=item $change-E<gt>text_mod()

True if the text (content) was modified.

=back

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

package SVN::Fs::PathChange;
use SVN::Base qw(Fs svn_fs_path_change_);

1;
