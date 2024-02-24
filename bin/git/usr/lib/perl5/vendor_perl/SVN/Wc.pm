use strict;
use warnings;

package SVN::Wc;
use SVN::Base qw(Wc svn_wc_);
use SVN::Core;

=head1 NAME

SVN::Wc - Subversion working copy functions

=head1 SYNOPSIS

Incomplete

=cut

swig_init_asp_dot_net_hack($SVN::Core::gpool);

=head1 FUNCTIONS

=over 4

=item SVN::Wc::parse_externals_description3($parent_directory, $desc, $canonicalize_url, $pool);

Parse the string $desc as an C<svn:externals> value and return a reference 
to an array of L<_p_svn_wc_external_item2_t|svn_wc_external_item2_t> objects. 
If $canonicalize_url is true, canonicalize the C<url> member of those objects.  
$parent_directory is only used in constructing error strings.

=back

=cut

=head1 OBJECTS

=cut

package _p_svn_wc_t;

=head2 svn_wc_status2_t

=over 4

=item $wcstat-E<gt>entry()

A svn_wc_entry_t object for the item.  Can be undef if not under version
control.

=item $wcstat-E<gt>text_status()

An integer representing the status of the item's text.  Can be one of the
$SVN::Wc::Status::* constants.

=item $wcstat-E<gt>prop_status()

An integer representing the status of the item's properties.  Can be one of the
$SVN::Wc::Status::* constants.

=item $wcstat-E<gt>locked()

A boolean telling if the item is locked.  A directory can be locked if a
working copy update was interrupted.

=item $wcstat-E<gt>copied()

A boolean telling if the item was copied.  A file or directory can be copied if
it's scheduled for addition-with-history (or part of a subtree that is
scheduled as such).

=item $wcstat-E<gt>switched()

A boolean telling if the item was switched.  A file or directory can be
switched if the switch command has been used.

=item $wcstat-E<gt>repos_text_status()

An integer representing the status of the item's text in the repository.  Can
be one of the $SVN::Wc::Status::* constants.


=item $wcstat-E<gt>repos_prop_status()

An integer representing the status of the item's properties in the repository.
Can be one of the $SVN::Wc::Status::* constants.

=item $wcstat-E<gt>repos_lock()

A svn_lock_t object representing the entry's lock in the repository, if any.

=item $wcstat-E<gt>url()

The url (actual or expected) of the item.

=item $wcstat-E<gt>ood_last_cmt_rev()

An integer representing the youngest committed revision or $SVN::Core::INVALID_REVNUM is not out of date.

=item $wcstat-E<gt>ood_last_cmt_date()

The date of the most recent commit as microseconds since 00:00:00 January 1, 1970 UTC or 0 if not out of date.

=item $wcstat-E<gt>ood_kind()

An integer representing the kind of the youngest commit.  Can be any of the $SVN::Node::* constants.  Will be $SVN::Node::none if not out of date.

=item $wcstat-E<gt>tree_conflict()

A svn_wc_conflict_description_t object if the entry is the victim of a tree conflict or undef.

=item $wcstat-E<gt>file_external()

A boolean telling if the item is a file that was added to the working copy as an svn:externals.  If file_external is TRUE, then switched is always FALSE.

=item $wcstat-E<gt>pristine_text_status()

An integer representing the status of the item's text as compared to the pristine base of the file.  Can be one of the $SVN::Wc::Status::* constants.

=item $wcstat-E<gt>pristine_prop_status()

An integer representing the status of the item's properties as compared to the pristine base of the node.  Can be one of the $SVN::Wc::Status::* constants.

=back

=cut

package _p_svn_wc_status2_t;
use SVN::Base qw(Wc svn_wc_status2_t_);

=head2 svn_wc_status_t

Same as svn_wc_status2_t, but without the repos_lock, url, ood_last_cmt_rev, ood_last_cmt_date, ood_kind, ood_last_cmt_author, tree_conflict, file_external, pristine_text_status, pristine_prop_status fields.

=cut

package _p_svn_wc_status_t;
use SVN::Base qw(Wc svn_wc_status_t_);

=head2 svn_wc_entry_t

=over 4

=item $wcent-E<gt>name()

Entry's name.

=item $wcent-E<gt>revision()

Base revision.

=item $wcent-E<gt>url()

URL in repository.

=item $wcent-E<gt>repos()

Canonical repository URL.

=item $wcent-E<gt>uuid()

Repository uuid.

=item $wcent-E<gt>kind()

The kind of node.  One of the following constants:
$SVN::Node::none, $SVN::Node::file,
$SVN::Node::dir, $SVN::Node::unknown.

=item $wcent-E<gt>schedule()

Scheduling.  One of the SVN::Wc::Schedule::* constants.

=item $wcent-E<gt>copied()

In a copied state.

=item $wcent-E<gt>deleted()

Deleted, but parent rev lags behind.

=item $wcent-E<gt>absent()

Absent -- we know an entry of this name exists, but that's all (usually this
happens because of authz restrictions)

=item $wcent-E<gt>incomplete()

For THIS_DIR entry, implies whole entries file is incomplete.

=item $wcent-E<gt>copyfrom_url()

Copyfrom location.

=item $wcent-E<gt>copyfrom_rev()

Copyfrom revision.

=item $wcent-E<gt>conflict_old()

Old version of conflicted file.

=item $wcent-E<gt>conflict_new()

New version of conflicted file.

=item $wcent-E<gt>conflict_wrk()

Working version of conflicted file.

=item $wcent-E<gt>prejfile()

Property reject file.

=item $wcent-E<gt>text_time()

Last up-to-date time for text contents (0 means no information available).

=item $wcent-E<gt>prop_time()

Last up-to-date time for properties (0 means no information available).

=item $wcent-E<gt>checksum()

Base-64 encoded checksum for the untranslated text base file, can be undef for
backwards compatibility.

=item $wcent-E<gt>cmt_rev()

Last revision this was changed.

=item $wcent-E<gt>cmt_date()

Last date this was changed.

=item $wcent-E<gt>cmt_author()

Last commit author of this item.

=back

=cut

package _p_svn_wc_entry_t;
# still need to check if the function prototype allows it to be called
# as method.
use SVN::Base qw(Wc svn_wc_entry_t_);

=head2 svn_wc_external_item2_t

=over 4

=item $ext-E<gt>target_dir()

The name of the subdirectory into which this external should be
checked out.  This is relative to the parent directory that
holds this external item.  

=item $ext-E<gt>url()

Where to check out from. This is possibly a relative external URL, as
allowed in externals definitions, but without the peg revision.

=item $ext-E<gt>revision()

What revision to check out,
a L<svn_opt_revision_t|SVN::Core/svn_opt_revision_t> object.
The only valid kind()s for this are $SVN::Core::opt_revision_number,
$SVN::Core::opt_revision_date, and $SVN::Core::opt_revision_head.

=item $ext-E<gt>peg_revision()

The peg revision to use when checking out, 
a L<svn_opt_revision_t|SVN::Core/svn_opt_revision_t> object.
The only valid kind()s for this are $SVN::Core::opt_revision_number,
$SVN::Core::opt_revision_date, and $SVN::Core::opt_revision_head.

=back

=cut

package _p_svn_wc_external_item2_t;
use SVN::Base qw(Wc svn_wc_external_item2_t_);

=head1 CONSTANTS

=head2 SVN::Wc::Notify::Action

=over 4

=item $SVN::Wc::Notify::Action::add

Adding a path to revision control.

=item $SVN::Wc::Notify::Action::copy

Copying a versioned path.

=item $SVN::Wc::Notify::Action::delete

Deleting a versioned path.

=item $SVN::Wc::Notify::Action::restore

Restoring a missing path from the pristine text-base.

=item $SVN::Wc::Notify::Action::revert

Reverting a modified path.

=item $SVN::Wc::Notify::Action::failed_revert

A revert operation has failed.

=item $SVN::Wc::Notify::Action::resolved

Resolving a conflict.

=item $SVN::Wc::Notify::Action::skip

Skipping a path.

=item $SVN::Wc::Notify::Action::update_delete

Got a delete in an update.

=item $SVN::Wc::Notify::Action::update_add

Got an add in an update.

=item $SVN::Wc::Notify::Action::update_update

Got any other action in an update.

=item $SVN::Wc::Notify::Action::update_completed

The last notification in an update (including updates of externals).

=item $SVN::Wc::Notify::Action::update_external

Updating an external module.

=item $SVN::Wc::Notify::Action::status_completed

The last notification in a status (including status on externals).

=item $SVN::Wc::Notify::Action::status_external

Running status on an external module.

=item $SVN::Wc::Notify::Action::commit_modified

Committing a modification.

=item $SVN::Wc::Notify::Action::commit_added

Committing an addition.

=item $SVN::Wc::Notify::Action::commit_deleted

Committing a deletion.

=item $SVN::Wc::Notify::Action::commit_replaced

Committing a replacement.

=item $SVN::Wc::Notify::Action::commit_postfix_txdelta

Transmitting post-fix text-delta data for a file.

=item $SVN::Wc::Notify::Action::blame_revision

Processed a single revision's blame.

=back

=cut

# no reasonable prefix for these enums
# so we have to do them one by one to import.
package SVN::Wc::Notify::Action;
our $add = $SVN::Wc::notify_add;
our $copy = $SVN::Wc::notify_copy;
our $delete = $SVN::Wc::notify_delete;
our $restore = $SVN::Wc::notify_restore;
our $revert = $SVN::Wc::notify_revert;
our $failed_revert = $SVN::Wc::notify_failed_revert;
our $resolved = $SVN::Wc::notify_resolved;
our $skip = $SVN::Wc::notify_skip;
our $update_delete = $SVN::Wc::notify_update_delete;
our $update_add = $SVN::Wc::notify_update_add;
our $update_update = $SVN::Wc::notify_update_update;
our $update_completed = $SVN::Wc::notify_update_completed;
our $update_external = $SVN::Wc::notify_update_external;
our $status_completed = $SVN::Wc::notify_status_completed;
our $status_external = $SVN::Wc::notify_status_external;
our $commit_modified = $SVN::Wc::notify_commit_modified;
our $commit_added = $SVN::Wc::notify_commit_added;
our $commit_deleted = $SVN::Wc::notify_commit_deleted;
our $commit_replaced = $SVN::Wc::notify_commit_replaced;
our $commit_postfix_txdelta = $SVN::Wc::notify_commit_postfix_txdelta;
our $blame_revision = $SVN::Wc::notify_blame_revision;

=head2 SVN::Wc::Notify::State

=over 4

=item $SVN::Wc::Notify::State::unknown

Notifier doesn't know or isn't saying.

=item $SVN::Wc::Notify::State::unchanged

The state did not change.

=item $SVN::Wc::Notify::State::missing

The item wasn't present.

=item $SVN::Wc::Notify::State::obstructed

An unversioned item obstructed work.

=item $SVN::Wc::Notify::State::changed

Pristine state was modified.

=item $SVN::Wc::Notify::State::merged

Modified state had mods merged in.

=item $SVN::Wc::Notify::State::conflicted

Modified state got conflicting mods.

=back

=cut

package SVN::Wc::Notify::State;
use SVN::Base qw(Wc svn_wc_notify_state_);

=head2 SVN::Wc::Schedule

=over 4

=item $SVN::Wc::Schedule::normal

Nothing special here.

=item $SVN::Wc::Schedule::add

Slated for addition.

=item $SVN::Wc::Schedule::delete

Slated for deletion.

=item $SVN::Wc::Schedule::replace

Slated for replacement (delete + add)

=back

=cut

package SVN::Wc::Schedule;
use SVN::Base qw(Wc svn_wc_schedule_);

=head2 SVN::Wc::Status

=over 4

=item $SVN::Wc::Status::none

Does not exist.

=item $SVN::Wc::Status::unversioned

Is not a versioned node in this working copy.

=item $SVN::Wc::Status::normal

Exists, but uninteresting.

=item $SVN::Wc::Status::added

Is scheduled for addition.

=item $SVN::Wc::Status::missing

Under version control but missing.

=item $SVN::Wc::Status::deleted

Scheduled for deletion.

=item $SVN::Wc::Status::replaced

Was deleted and then re-added.

=item $SVN::Wc::Status::modified

Text or props have been modified.

=item $SVN::Wc::Status::merged

Local mods received repos mods.

=item $SVN::Wc::Status::conflicted

Local mods received conflicting mods.

=item $SVN::Wc::Status::ignored

A node marked as ignored.

=item $SVN::Wc::Status::obstructed

An unversioned resource is in the way of the versioned resource.

=item $SVN::Wc::Status::external

An unversioned path populated by an svn:externals property.

=item $SVN::Wc::Status::incomplete

A directory doesn't contain a complete entries list.

=back

=cut

package SVN::Wc::Status;
use SVN::Base qw(Wc svn_wc_status_);

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
