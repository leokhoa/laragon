use strict;
use warnings;

package SVN::Delta;
use SVN::Base qw(Delta svn_delta_);

=head1 NAME

SVN::Delta - Subversion delta functions

=head1 SYNOPSIS

    require SVN::Core;
    require SVN::Repos;
    require SVN::Delta;

    # driving an editor
    my $editor = SVN::Delta::Editor->
        new(SVN::Repos::get_commit_editor($repos, "file://$repospath",
                                          '/', 'root', 'FOO', \&committed));

    my $rootbaton = $editor->open_root(0);

    my $fbaton = $editor->add_file('filea', $rootbaton,
                                   undef, -1);

    my $ret = $editor->apply_textdelta($fbaton, undef);
    SVN::TxDelta::send_string("FILEA CONTENT", @$ret);

    # implement an editor in perl
    SVN::Repos::dir_delta($root1, $path, undef,
                          $root2, $path,
                          SVN::Delta::Editor->new(_debug=>1),
                          1, 1, 0, 1

=head1 DESCRIPTION

SVN::Delta wraps delta related function in subversion. The most
important one is SVN::Delta::Editor, the interface for describing tree
deltas. by default SVN::Delta::Editor relays method calls to its
internal member C<_editor>, which could either be an editor in C (such
as the one you get from get_commit_editor), or another
SVN::Delta::Editor object.

=head1 SVN::Delta::Editor

=head2 Driving Editors

If you want to drive a native editor (such as commit_editor obtained
by SVN::Repos::get_commit_editor), create a SVN::Delta::Editor object
with the native editor/baton pair. The object will then be ready to
use and its method calls will be relayed to the native editor.

=head2 Implementing Editors

If you want to implement an editor, subclass SVN::Delta::Editor and
implement the editors callbacks. see the METHODS section below.

=head2 CONSTRUCTOR - new(...)

=over

=item new($editor, $editor_baton)

Link to the native editor

=back

You can also pass a hash array to new:

=over

=item _debug

Turn on debug.

=item _editor

An arrayref of the editor/baton pair or another SVN::Delta::Editor
object to link with.

=back

=head2 METHODS

Please consult the svn_delta.h section in the Subversion API. Member
functions of svn_delta_editor_t could be called as methods of
SVN::Delta::Editor objects, with the edit_baton omitted. The pool is
also optional.

If you are subclassing, the methods take exactly the same arguments as
the member functions (note that void ** are returned data though as
throughout the perl bindings), with the edit_baton omitted.

=cut

package SVN::TxDelta;
use SVN::Base qw(Delta svn_txdelta_ apply);

*new = *SVN::_Delta::svn_txdelta;

# special case for backward compatibility.  When called with an additional
# argument "md5", it's the old style and don't return the md5.
sub apply {
    if (@_ == 5 || (@_ == 4 && ref($_[-1]) ne 'SVN::Pool' && ref($_[-1]) ne '_p_apr_pool_t')) {
        # we're called as 
        # apply($source, $target, $result_digest, $error_info [, $pool]) 
        splice(@_, 2, 1);
        my @ret = SVN::_Delta::svn_txdelta_apply(@_);
        return @ret[1,2];
    }
    goto \&SVN::_Delta::svn_txdelta_apply;
}

package _p_svn_txdelta_op_t;
use SVN::Base qw(Delta svn_txdelta_op_t_);

package _p_svn_txdelta_window_t;
use SVN::Base qw(Delta svn_txdelta_window_t_);

package SVN::Delta::Editor;
use SVN::Base qw(Delta svn_delta_editor_);

*invoke_set_target_revision = *SVN::_Delta::svn_delta_editor_invoke_set_target_revision;

sub convert_editor {
    my $self = shift;
    $self->{_editor} = $_[0], return 1
        if UNIVERSAL::isa($_[0], __PACKAGE__);
    if (ref($_[0]) && $_[0]->isa('_p_svn_delta_editor_t')) {
        @{$self}{qw/_editor _baton/} = @_;
        return 1;
    }
    return 0;
}

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    unless ($self->convert_editor(@_)) {
        %$self = @_;
        $self->convert_editor(@{$self->{_editor}})
            if $self->{_editor};
    }

    return $self;
}

our $AUTOLOAD;

sub AUTOLOAD {
    no warnings 'uninitialized';
    return unless $_[0]->{_editor};
    my $class = ref($_[0]);
    my $func = $AUTOLOAD;
    $func =~ s/.*:://;
    warn "$func: ".join(',',@_)."\n" if $_[0]->{_debug};
    return unless $func =~ m/[^A-Z]/;

    my %ebaton = ( set_target_revision => 1,
                   open_root => 1,
                   close_edit => 1,
                   abort_edit => 1,
                 );

    my $self = shift;
    no strict 'refs';

    my @ret = UNIVERSAL::isa($self->{_editor}, __PACKAGE__) ?
        $self->{_editor}->$func(@_) :
        eval { &{"invoke_$func"}($self->{_editor},
                                 $ebaton{$func} ? $self->{_baton} : (), @_) };

    die $@ if $@;

    return @ret ? $#ret == 0 ? $ret[0] : [@ret] : undef;
}

=head1 BUGS

Functions returning editor/baton pair should really be typemapped to a
SVN::Delta::Editor object.

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
