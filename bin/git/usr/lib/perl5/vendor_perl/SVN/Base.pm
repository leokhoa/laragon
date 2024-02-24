package SVN::Base;

=head1 NAME

SVN::Base - Base class for importing symbols for svn modules

=head1 SYNOPSIS

    # Load the svn_ra_* functions into the SVN::Ra namespace.
    package SVN::Ra;
    use SVN::Base qw(Ra svn_ra_);

    # Load svn_config_t structure accessors in the magic namcespace
    # provided by swig, so we could use it returned by other functions
    package _p_svn_config_t;
    use SVN::Base qw(Core svn_config_);

=head1 DESCRIPTION

SVN::Base is a module importing the subversion perl bindings raw
symbols created by swig, into proper namespace and make them easier to
use.

It will also find the accessors for members of a C struct, create an
simpler accessor function like C<$data-E<gt>field()> and
C<$data-E<gt>field($new_value)>.

Once you understand the convention of subversion functions in perl
bindings, you could look at the subversion api and write them in perl.
The API is available in the source header files or online at
L<https://subversion.apache.org/docs/api/latest/>.

=head1 INTERNALS

The perl bindings of swig wraps raw functions into different perl
modules, for example, SVN::_Core, SVN::_Repos. Upon import, SVN::Base
bootstrap the requested module if it's not yet loaded, and iterate
over the symbols provided in that module, it them puts the function
with prefix trimmed in the namespace of the caller for this import.

The 3rd through the last parameter is a list of symbol endings that
you wish for SVN::Base not to import into your namespace.  This is useful
for cases where you may want to import certain symbols differently than
normally.

=head1 CAVEATS

SVN::Base consider a function as structure member accessor if it is
postfixed ``_get'' or ``_set''. Real functions with this postfixes
will need extra handling.

=cut

sub import {
    my (undef, $pkg, $prefix, @ignore) = @_;
    no warnings 'uninitialized';
    unless (${"SVN::_${pkg}::ISA"}[0] eq 'DynaLoader') {
        @{"SVN::_${pkg}::ISA"} = qw(DynaLoader);
        eval qq'
package SVN::_$pkg;
require DynaLoader;
bootstrap SVN::_$pkg;
1;
    ' or die $@;
    };

    my $caller = caller(0);

    my $prefix_re = qr/(?i:$prefix)/;
    my $ignore_re = join('|', @ignore);
    for (keys %{"SVN::_${pkg}::"}) {
        my $name = $_;
        next unless s/^$prefix_re//;
        next if $ignore_re && m/$ignore_re/;

        # insert the accessor
        if (m/(.*)_get$/) {
            my $member = $1;
            *{"${caller}::$1"} = sub {
                &{"SVN::_${pkg}::${prefix}${member}_".
                    (@_ > 1 ? 'set' : 'get')}(@_)
            }
        }
        elsif (m/(.*)_set$/) {
        }
        else {
            *{"${caller}::$_"} = ${"SVN::_${pkg}::"}{$name};
        }
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
