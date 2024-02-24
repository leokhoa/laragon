package Try::Tiny; # git description: v0.30-11-g1b81d0a
use 5.006;
# ABSTRACT: Minimal try/catch with proper preservation of $@

our $VERSION = '0.31';

use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT = our @EXPORT_OK = qw(try catch finally);

use Carp;
$Carp::Internal{+__PACKAGE__}++;

BEGIN {
  my $su = $INC{'Sub/Util.pm'} && defined &Sub::Util::set_subname;
  my $sn = $INC{'Sub/Name.pm'} && eval { Sub::Name->VERSION(0.08) };
  unless ($su || $sn) {
    $su = eval { require Sub::Util; } && defined &Sub::Util::set_subname;
    unless ($su) {
      $sn = eval { require Sub::Name; Sub::Name->VERSION(0.08) };
    }
  }

  *_subname = $su ? \&Sub::Util::set_subname
            : $sn ? \&Sub::Name::subname
            : sub { $_[1] };
  *_HAS_SUBNAME = ($su || $sn) ? sub(){1} : sub(){0};
}

my %_finally_guards;

# Need to prototype as @ not $$ because of the way Perl evaluates the prototype.
# Keeping it at $$ means you only ever get 1 sub because we need to eval in a list
# context & not a scalar one

sub try (&;@) {
  my ( $try, @code_refs ) = @_;

  # we need to save this here, the eval block will be in scalar context due
  # to $failed
  my $wantarray = wantarray;

  # work around perl bug by explicitly initializing these, due to the likelyhood
  # this will be used in global destruction (perl rt#119311)
  my ( $catch, @finally ) = ();

  # find labeled blocks in the argument list.
  # catch and finally tag the blocks by blessing a scalar reference to them.
  foreach my $code_ref (@code_refs) {

    if ( ref($code_ref) eq 'Try::Tiny::Catch' ) {
      croak 'A try() may not be followed by multiple catch() blocks'
        if $catch;
      $catch = ${$code_ref};
    } elsif ( ref($code_ref) eq 'Try::Tiny::Finally' ) {
      push @finally, ${$code_ref};
    } else {
      croak(
        'try() encountered an unexpected argument ('
      . ( defined $code_ref ? $code_ref : 'undef' )
      . ') - perhaps a missing semi-colon before or'
      );
    }
  }

  # FIXME consider using local $SIG{__DIE__} to accumulate all errors. It's
  # not perfect, but we could provide a list of additional errors for
  # $catch->();

  # name the blocks if we have Sub::Name installed
  _subname(caller().'::try {...} ' => $try)
    if _HAS_SUBNAME;

  # set up scope guards to invoke the finally blocks at the end.
  # this should really be a function scope lexical variable instead of
  # file scope + local but that causes issues with perls < 5.20 due to
  # perl rt#119311
  local $_finally_guards{guards} = [
    map Try::Tiny::ScopeGuard->_new($_),
    @finally
  ];

  # save the value of $@ so we can set $@ back to it in the beginning of the eval
  # and restore $@ after the eval finishes
  my $prev_error = $@;

  my ( @ret, $error );

  # failed will be true if the eval dies, because 1 will not be returned
  # from the eval body
  my $failed = not eval {
    $@ = $prev_error;

    # evaluate the try block in the correct context
    if ( $wantarray ) {
      @ret = $try->();
    } elsif ( defined $wantarray ) {
      $ret[0] = $try->();
    } else {
      $try->();
    };

    return 1; # properly set $failed to false
  };

  # preserve the current error and reset the original value of $@
  $error = $@;
  $@ = $prev_error;

  # at this point $failed contains a true value if the eval died, even if some
  # destructor overwrote $@ as the eval was unwinding.
  if ( $failed ) {
    # pass $error to the finally blocks
    push @$_, $error for @{$_finally_guards{guards}};

    # if we got an error, invoke the catch block.
    if ( $catch ) {
      # This works like given($error), but is backwards compatible and
      # sets $_ in the dynamic scope for the body of C<$catch>
      for ($error) {
        return $catch->($error);
      }

      # in case when() was used without an explicit return, the C<for>
      # loop will be aborted and there's no useful return value
    }

    return;
  } else {
    # no failure, $@ is back to what it was, everything is fine
    return $wantarray ? @ret : $ret[0];
  }
}

sub catch (&;@) {
  my ( $block, @rest ) = @_;

  croak 'Useless bare catch()' unless wantarray;

  _subname(caller().'::catch {...} ' => $block)
    if _HAS_SUBNAME;
  return (
    bless(\$block, 'Try::Tiny::Catch'),
    @rest,
  );
}

sub finally (&;@) {
  my ( $block, @rest ) = @_;

  croak 'Useless bare finally()' unless wantarray;

  _subname(caller().'::finally {...} ' => $block)
    if _HAS_SUBNAME;
  return (
    bless(\$block, 'Try::Tiny::Finally'),
    @rest,
  );
}

{
  package # hide from PAUSE
    Try::Tiny::ScopeGuard;

  use constant UNSTABLE_DOLLARAT => ("$]" < '5.013002') ? 1 : 0;

  sub _new {
    shift;
    bless [ @_ ];
  }

  sub DESTROY {
    my ($code, @args) = @{ $_[0] };

    local $@ if UNSTABLE_DOLLARAT;
    eval {
      $code->(@args);
      1;
    } or do {
      warn
        "Execution of finally() block $code resulted in an exception, which "
      . '*CAN NOT BE PROPAGATED* due to fundamental limitations of Perl. '
      . 'Your program will continue as if this event never took place. '
      . "Original exception text follows:\n\n"
      . (defined $@ ? $@ : '$@ left undefined...')
      . "\n"
      ;
    }
  }
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

Try::Tiny - Minimal try/catch with proper preservation of $@

=head1 VERSION

version 0.31

=head1 SYNOPSIS

You can use Try::Tiny's C<try> and C<catch> to expect and handle exceptional
conditions, avoiding quirks in Perl and common mistakes:

  # handle errors with a catch handler
  try {
    die "foo";
  } catch {
    warn "caught error: $_"; # not $@
  };

You can also use it like a standalone C<eval> to catch and ignore any error
conditions.  Obviously, this is an extreme measure not to be undertaken
lightly:

  # just silence errors
  try {
    die "foo";
  };

=head1 DESCRIPTION

This module provides bare bones C<try>/C<catch>/C<finally> statements that are designed to
minimize common mistakes with eval blocks, and NOTHING else.

This is unlike L<TryCatch> which provides a nice syntax and avoids adding
another call stack layer, and supports calling C<return> from the C<try> block to
return from the parent subroutine. These extra features come at a cost of a few
dependencies, namely L<Devel::Declare> and L<Scope::Upper> which are
occasionally problematic, and the additional catch filtering uses L<Moose>
type constraints which may not be desirable either.

The main focus of this module is to provide simple and reliable error handling
for those having a hard time installing L<TryCatch>, but who still want to
write correct C<eval> blocks without 5 lines of boilerplate each time.

It's designed to work as correctly as possible in light of the various
pathological edge cases (see L</BACKGROUND>) and to be compatible with any style
of error values (simple strings, references, objects, overloaded objects, etc).

If the C<try> block dies, it returns the value of the last statement executed in
the C<catch> block, if there is one. Otherwise, it returns C<undef> in scalar
context or the empty list in list context. The following examples all
assign C<"bar"> to C<$x>:

  my $x = try { die "foo" } catch { "bar" };
  my $x = try { die "foo" } || "bar";
  my $x = (try { die "foo" }) // "bar";

  my $x = eval { die "foo" } || "bar";

You can add C<finally> blocks, yielding the following:

  my $x;
  try { die 'foo' } finally { $x = 'bar' };
  try { die 'foo' } catch { warn "Got a die: $_" } finally { $x = 'bar' };

C<finally> blocks are always executed making them suitable for cleanup code
which cannot be handled using local.  You can add as many C<finally> blocks to a
given C<try> block as you like.

Note that adding a C<finally> block without a preceding C<catch> block
suppresses any errors. This behaviour is consistent with using a standalone
C<eval>, but it is not consistent with C<try>/C<finally> patterns found in
other programming languages, such as Java, Python, Javascript or C#. If you
learned the C<try>/C<finally> pattern from one of these languages, watch out for
this.

=head1 EXPORTS

All functions are exported by default using L<Exporter>.

If you need to rename the C<try>, C<catch> or C<finally> keyword consider using
L<Sub::Import> to get L<Sub::Exporter>'s flexibility.

=over 4

=item try (&;@)

Takes one mandatory C<try> subroutine, an optional C<catch> subroutine and C<finally>
subroutine.

The mandatory subroutine is evaluated in the context of an C<eval> block.

If no error occurred the value from the first block is returned, preserving
list/scalar context.

If there was an error and the second subroutine was given it will be invoked
with the error in C<$_> (localized) and as that block's first and only
argument.

C<$@> does B<not> contain the error. Inside the C<catch> block it has the same
value it had before the C<try> block was executed.

Note that the error may be false, but if that happens the C<catch> block will
still be invoked.

Once all execution is finished then the C<finally> block, if given, will execute.

=item catch (&;@)

Intended to be used in the second argument position of C<try>.

Returns a reference to the subroutine it was given but blessed as
C<Try::Tiny::Catch> which allows try to decode correctly what to do
with this code reference.

  catch { ... }

Inside the C<catch> block the caught error is stored in C<$_>, while previous
value of C<$@> is still available for use.  This value may or may not be
meaningful depending on what happened before the C<try>, but it might be a good
idea to preserve it in an error stack.

For code that captures C<$@> when throwing new errors (i.e.
L<Class::Throwable>), you'll need to do:

  local $@ = $_;

=item finally (&;@)

  try     { ... }
  catch   { ... }
  finally { ... };

Or

  try     { ... }
  finally { ... };

Or even

  try     { ... }
  finally { ... }
  catch   { ... };

Intended to be the second or third element of C<try>. C<finally> blocks are always
executed in the event of a successful C<try> or if C<catch> is run. This allows
you to locate cleanup code which cannot be done via C<local()> e.g. closing a file
handle.

When invoked, the C<finally> block is passed the error that was caught.  If no
error was caught, it is passed nothing.  (Note that the C<finally> block does not
localize C<$_> with the error, since unlike in a C<catch> block, there is no way
to know if C<$_ == undef> implies that there were no errors.) In other words,
the following code does just what you would expect:

  try {
    die_sometimes();
  } catch {
    # ...code run in case of error
  } finally {
    if (@_) {
      print "The try block died with: @_\n";
    } else {
      print "The try block ran without error.\n";
    }
  };

B<You must always do your own error handling in the C<finally> block>. C<Try::Tiny> will
not do anything about handling possible errors coming from code located in these
blocks.

Furthermore B<exceptions in C<finally> blocks are not trappable and are unable
to influence the execution of your program>. This is due to limitation of
C<DESTROY>-based scope guards, which C<finally> is implemented on top of. This
may change in a future version of Try::Tiny.

In the same way C<catch()> blesses the code reference this subroutine does the same
except it bless them as C<Try::Tiny::Finally>.

=back

=head1 BACKGROUND

There are a number of issues with C<eval>.

=head2 Clobbering $@

When you run an C<eval> block and it succeeds, C<$@> will be cleared, potentially
clobbering an error that is currently being caught.

This causes action at a distance, clearing previous errors your caller may have
not yet handled.

C<$@> must be properly localized before invoking C<eval> in order to avoid this
issue.

More specifically,
L<before Perl version 5.14.0|perl5140delta/"Exception Handling">
C<$@> was clobbered at the beginning of the C<eval>, which
also made it impossible to capture the previous error before you die (for
instance when making exception objects with error stacks).

For this reason C<try> will actually set C<$@> to its previous value (the one
available before entering the C<try> block) in the beginning of the C<eval>
block.

=head2 Localizing $@ silently masks errors

Inside an C<eval> block, C<die> behaves sort of like:

  sub die {
    $@ = $_[0];
    return_undef_from_eval();
  }

This means that if you were polite and localized C<$@> you can't die in that
scope, or your error will be discarded (printing "Something's wrong" instead).

The workaround is very ugly:

  my $error = do {
    local $@;
    eval { ... };
    $@;
  };

  ...
  die $error;

=head2 $@ might not be a true value

This code is wrong:

  if ( $@ ) {
    ...
  }

because due to the previous caveats it may have been unset.

C<$@> could also be an overloaded error object that evaluates to false, but
that's asking for trouble anyway.

The classic failure mode (fixed in L<Perl 5.14.0|perl5140delta/"Exception Handling">) is:

  sub Object::DESTROY {
    eval { ... }
  }

  eval {
    my $obj = Object->new;

    die "foo";
  };

  if ( $@ ) {

  }

In this case since C<Object::DESTROY> is not localizing C<$@> but still uses
C<eval>, it will set C<$@> to C<"">.

The destructor is called when the stack is unwound, after C<die> sets C<$@> to
C<"foo at Foo.pm line 42\n">, so by the time C<if ( $@ )> is evaluated it has
been cleared by C<eval> in the destructor.

The workaround for this is even uglier than the previous ones. Even though we
can't save the value of C<$@> from code that doesn't localize, we can at least
be sure the C<eval> was aborted due to an error:

  my $failed = not eval {
    ...

    return 1;
  };

This is because an C<eval> that caught a C<die> will always return a false
value.

=head1 ALTERNATE SYNTAX

Using Perl 5.10 you can use L<perlsyn/"Switch statements"> (but please don't,
because that syntax has since been deprecated because there was too much
unexpected magical behaviour).

=for stopwords topicalizer

The C<catch> block is invoked in a topicalizer context (like a C<given> block),
but note that you can't return a useful value from C<catch> using the C<when>
blocks without an explicit C<return>.

This is somewhat similar to Perl 6's C<CATCH> blocks. You can use it to
concisely match errors:

  try {
    require Foo;
  } catch {
    when (/^Can't locate .*?\.pm in \@INC/) { } # ignore
    default { die $_ }
  };

=head1 CAVEATS

=over 4

=item *

C<@_> is not available within the C<try> block, so you need to copy your
argument list. In case you want to work with argument values directly via C<@_>
aliasing (i.e. allow C<$_[1] = "foo">), you need to pass C<@_> by reference:

  sub foo {
    my ( $self, @args ) = @_;
    try { $self->bar(@args) }
  }

or

  sub bar_in_place {
    my $self = shift;
    my $args = \@_;
    try { $_ = $self->bar($_) for @$args }
  }

=item *

C<return> returns from the C<try> block, not from the parent sub (note that
this is also how C<eval> works, but not how L<TryCatch> works):

  sub parent_sub {
    try {
      die;
    }
    catch {
      return;
    };

    say "this text WILL be displayed, even though an exception is thrown";
  }

Instead, you should capture the return value:

  sub parent_sub {
    my $success = try {
      die;
      1;
    };
    return unless $success;

    say "This text WILL NEVER appear!";
  }
  # OR
  sub parent_sub_with_catch {
    my $success = try {
      die;
      1;
    }
    catch {
      # do something with $_
      return undef; #see note
    };
    return unless $success;

    say "This text WILL NEVER appear!";
  }

Note that if you have a C<catch> block, it must return C<undef> for this to work,
since if a C<catch> block exists, its return value is returned in place of C<undef>
when an exception is thrown.

=item *

C<try> introduces another caller stack frame. L<Sub::Uplevel> is not used. L<Carp>
will not report this when using full stack traces, though, because
C<%Carp::Internal> is used. This lack of magic is considered a feature.

=for stopwords unhygienically

=item *

The value of C<$_> in the C<catch> block is not guaranteed to be the value of
the exception thrown (C<$@>) in the C<try> block.  There is no safe way to
ensure this, since C<eval> may be used unhygienically in destructors.  The only
guarantee is that the C<catch> will be called if an exception is thrown.

=item *

The return value of the C<catch> block is not ignored, so if testing the result
of the expression for truth on success, be sure to return a false value from
the C<catch> block:

  my $obj = try {
    MightFail->new;
  } catch {
    ...

    return; # avoid returning a true value;
  };

  return unless $obj;

=item *

C<$SIG{__DIE__}> is still in effect.

Though it can be argued that C<$SIG{__DIE__}> should be disabled inside of
C<eval> blocks, since it isn't people have grown to rely on it. Therefore in
the interests of compatibility, C<try> does not disable C<$SIG{__DIE__}> for
the scope of the error throwing code.

=item *

Lexical C<$_> may override the one set by C<catch>.

For example Perl 5.10's C<given> form uses a lexical C<$_>, creating some
confusing behavior:

  given ($foo) {
    when (...) {
      try {
        ...
      } catch {
        warn $_; # will print $foo, not the error
        warn $_[0]; # instead, get the error like this
      }
    }
  }

Note that this behavior was changed once again in
L<Perl5 version 18|https://metacpan.org/module/perldelta#given-now-aliases-the-global-_>.
However, since the entirety of lexical C<$_> is now L<considered experimental
|https://metacpan.org/module/perldelta#Lexical-_-is-now-experimental>, it
is unclear whether the new version 18 behavior is final.

=back

=head1 SEE ALSO

=over 4

=item L<Syntax::Keyword::Try>

Only available on perls >= 5.14, with a slightly different syntax (e.g. no trailing C<;> because
it's actually a keyword, not a sub, but this means you can C<return> and C<next> within it). Use
L<Feature::Compat::Try> to automatically switch to the native C<try> syntax in newer perls (when
available). See also L<Try Catch Exception Handling|perlsyn/Try-Catch-Exception-Handling>.

=item L<TryCatch>

Much more feature complete, more convenient semantics, but at the cost of
implementation complexity.

=item L<autodie>

Automatic error throwing for builtin functions and more. Also designed to
work well with C<given>/C<when>.

=item L<Throwable>

A lightweight role for rolling your own exception classes.

=item L<Error>

Exception object implementation with a C<try> statement. Does not localize
C<$@>.

=item L<Exception::Class::TryCatch>

Provides a C<catch> statement, but properly calling C<eval> is your
responsibility.

The C<try> keyword pushes C<$@> onto an error stack, avoiding some of the
issues with C<$@>, but you still need to localize to prevent clobbering.

=back

=head1 LIGHTNING TALK

I gave a lightning talk about this module, you can see the slides (Firefox
only):

L<http://web.archive.org/web/20100628040134/http://nothingmuch.woobling.org/talks/takahashi.xul>

Or read the source:

L<http://web.archive.org/web/20100305133605/http://nothingmuch.woobling.org/talks/yapc_asia_2009/try_tiny.yml>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Try-Tiny>
(or L<bug-Try-Tiny@rt.cpan.org|mailto:bug-Try-Tiny@rt.cpan.org>).

=head1 AUTHORS

=over 4

=item *

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=item *

Jesse Luehrs <doy@tozt.net>

=back

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Peter Rabbitson Ricardo Signes Mark Fowler Graham Knop Aristotle Pagaltzis Dagfinn Ilmari Mannsåker Lukas Mai Alex anaxagoras Andrew Yates awalker chromatic cm-perl David Lowe Glenn Hans Dieter Pearcey Jens Berthold Jonathan Yu Marc Mims Stosberg Pali Paul Howarth Rudolf Leermakers

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Peter Rabbitson <ribasushi@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Mark Fowler <mark@twoshortplanks.com>

=item *

Graham Knop <haarg@haarg.org>

=item *

Aristotle Pagaltzis <pagaltzis@gmx.de>

=item *

Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>

=item *

Lukas Mai <l.mai@web.de>

=item *

Alex <alex@koban.(none)>

=item *

anaxagoras <walkeraj@gmail.com>

=item *

Andrew Yates <ayates@haddock.local>

=item *

awalker <awalker@sourcefire.com>

=item *

chromatic <chromatic@wgz.org>

=item *

cm-perl <cm-perl@users.noreply.github.com>

=item *

David Lowe <davidl@lokku.com>

=item *

Glenn Fowler <cebjyre@cpan.org>

=item *

Hans Dieter Pearcey <hdp@weftsoar.net>

=item *

Jens Berthold <jens@jebecs.de>

=item *

Jonathan Yu <JAWNSY@cpan.org>

=item *

Marc Mims <marc@questright.com>

=item *

Mark Stosberg <mark@stosberg.com>

=item *

Pali <pali@cpan.org>

=item *

Paul Howarth <paul@city-fan.org>

=item *

Rudolf Leermakers <rudolf@hatsuseno.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is Copyright (c) 2009 by יובל קוג'מן (Yuval Kogman).

This is free software, licensed under:

  The MIT (X11) License

=cut
