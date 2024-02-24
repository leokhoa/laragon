# Copyrights 1995-2019 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of the bundle MailTools.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md for Copyright.
# Licensed under the same terms as Perl itself.

package Mail::Internet;
use vars '$VERSION';
$VERSION = '2.21';

use strict;
# use warnings?  probably breaking too much code

use Carp;
use Mail::Header;
use Mail::Util    qw/mailaddress/;
use Mail::Address;


sub new(@)
{   my $call  = shift;
    my $arg   = @_ % 2 ? shift : undef;
    my %opt   = @_;

    my $class = ref($call) || $call;
    my $self  = bless {}, $class;

    $self->{mail_inet_head} = $opt{Header} if exists $opt{Header};
    $self->{mail_inet_body} = $opt{Body}   if exists $opt{Body};

    my $head = $self->head;
    $head->fold_length(delete $opt{FoldLength} || 79);
    $head->mail_from($opt{MailFrom}) if exists $opt{MailFrom};
    $head->modify(exists $opt{Modify} ? $opt{Modify} : 1);

    if(!defined $arg) { }
    elsif(ref($arg) eq 'ARRAY')
    {   $self->header($arg) unless exists $opt{Header};
        $self->body($arg)   unless exists $opt{Body};
    }
    elsif(defined fileno($arg))
    {   $self->read_header($arg) unless exists $opt{Header};
        $self->read_body($arg)   unless exists $opt{Body};
    }
    else
    {   croak "couldn't understand $arg to Mail::Internet constructor";
    }

    $self;
}


sub read(@)
{   my $self = shift;
    $self->read_header(@_);
    $self->read_body(@_);
}

sub read_body($)
{   my ($self, $fd) = @_;
    $self->body( [ <$fd> ] );
}

sub read_header(@)
{   my $head = shift->head;
    $head->read(@_);
    $head->header;
}


sub extract($)
{   my ($self, $lines) = @_;
    $self->head->extract($lines);
    $self->body($lines);
}


sub dup()
{   my $self = shift;
    my $dup  = ref($self)->new;

    my $body = $self->{mail_inet_body} || [];
    my $head = $self->{mail_inet_head};;

    $dup->{mail_inet_body} = [ @$body ];
    $dup->{mail_inet_head} = $head->dup if $head;
    $dup;
}

#---------------

sub body(;$@)
{   my $self = shift;

    return $self->{mail_inet_body} ||= []
        unless @_;

    $self->{mail_inet_body} = ref $_[0] eq 'ARRAY' ? $_[0] : [ @_ ];
}


sub head         { shift->{mail_inet_head} ||= Mail::Header->new }

#---------------

sub print($)
{   my $self = shift;
    my $fd   = shift || \*STDOUT;

    $self->print_header($fd)
       and print $fd "\n"
       and $self->print_body($fd);
}


sub print_header($) { shift->head->print(@_) }

sub print_body($)
{   my $self = shift;
    my $fd   = shift || \*STDOUT;

    foreach my $ln (@{$self->body})
    {    print $fd $ln or return 0;
    }

    1;
}


sub as_string()
{   my $self = shift;
    $self->head->as_string . "\n" . join '', @{$self->body};
}


sub as_mbox_string($)
{   my $self    = shift->dup;
    my $escaped = shift;

    $self->head->delete('Content-Length');
    $self->escape_from unless $escaped;
    $self->as_string . "\n";
}

#---------------

sub header       { shift->head->header(@_) }
sub fold         { shift->head->fold(@_) }
sub fold_length  { shift->head->fold_length(@_) }
sub combine      { shift->head->combine(@_) }


sub add(@)
{   my $head = shift->head;
    my $ret;
    while(@_)
    {   my ($tag, $line) = splice @_, 0, 2;
        $ret = $head->add($tag, $line, -1)
            or return undef;
    }

    $ret;
}


sub replace(@)
{   my $head = shift->head;
    my $ret;

    while(@_)
    {   my ($tag, $line) = splice @_, 0, 2;
        $ret = $head->replace($tag, $line, 0)
             or return undef;
    }

    $ret;
}


sub get(@)
{   my $head = shift->head;

    return map { $head->get($_) } @_
        if wantarray;

    foreach my $tag (@_)
    {   my $r = $head->get($tag);
        return $r if defined $r;
    }

    undef;
}


sub delete(@)
{   my $head = shift->head;
    map { $head->delete($_) } @_;
}

# Undocumented; unused???
sub empty()
{   my $self = shift;
    %$self = ();
    1;
}

#---------------

sub remove_sig($)
{   my $body   = shift->body;
    my $nlines = shift || 10;
    my $start  = @$body;

    my $i    = 0;
    while($i++ < $nlines && $start--)
    {   next if $body->[$start] !~ /^--[ ]?[\r\n]/;

        splice @$body, $start, $i;
        last;
    }
}


sub sign(@)
{   my ($self, %arg) = @_;
    my ($sig, @sig);

    if($sig = delete $arg{File})
    {   local *SIG;

        if(open(SIG, $sig))
        {   local $_;
            while(<SIG>) { last unless /^(--)?\s*$/ }
            @sig = ($_, <SIG>, "\n");
            close SIG;
        }
    }
    elsif($sig = delete $arg{Signature})
    {    @sig = ref($sig) ? @$sig : split(/\n/, $sig);
    }

    if(@sig)
    {   $self->remove_sig;
        s/[\r\n]*$/\n/ for @sig;
        push @{$self->body}, "-- \n", @sig;
    }

    $self;
}


sub tidy_body()
{   my $body = shift->body;

    shift @$body while @$body && $body->[0]  =~ /^\s*$/;
    pop @$body   while @$body && $body->[-1] =~ /^\s*$/;
    $body;
}

#---------------

sub reply(@)
{   my ($self, %arg) = @_;
    my $class = ref $self;
    my @reply;

    local *MAILHDR;
    if(open(MAILHDR, "$ENV{HOME}/.mailhdr")) 
    {    # User has defined a mail header template
         @reply = <MAILHDR>;
         close MAILHDR;
    }

    my $reply = $class->new(\@reply);

    # The Subject line
    my $subject = $self->get('Subject') || "";
    $subject = "Re: " . $subject
        if $subject =~ /\S+/ && $subject !~ /Re:/i;

    $reply->replace(Subject => $subject);

    # Locate who we are sending to
    my $to = $self->get('Reply-To')
          || $self->get('From')
          || $self->get('Return-Path')
          || "";

    my $sender = (Mail::Address->parse($to))[0];

    my $name = $sender->name;
    unless(defined $name)
    {    my $fr = $self->get('From');
         $fr    = (Mail::Address->parse($fr))[0] if defined $fr;
         $name  = $fr->name if defined $fr;
    }

    my $indent = $arg{Indent} || ">";
    if($indent =~ /\%/) 
    {   my %hash = ( '%' => '%');
        my @name = $name ? grep( {length $_} split /[\n\s]+/, $name) : '';

        $hash{f} = $name[0];
        $hash{F} = $#name ? substr($hash{f},0,1) : $hash{f};

        $hash{l} = $#name ? $name[$#name] : "";
        $hash{L} = substr($hash{l},0,1) || "";

        $hash{n} = $name || "";
        $hash{I} = join "", map {substr($_,0,1)} @name;

        $indent  =~ s/\%(.)/defined $hash{$1} ? $hash{$1} : $1/eg;
    }

    my $id     = $sender->address;
    $reply->replace(To => $id);

    # Find addresses not to include
    my $mailaddresses = $ENV{MAILADDRESSES} || "";

    my %nocc = (lc($id) => 1);
    $nocc{lc $_->address} = 1
        for Mail::Address->parse($reply->get('Bcc'), $mailaddresses);

    if($arg{ReplyAll})   # Who shall we copy this to
    {   my %cc;
        foreach my $addr (Mail::Address->parse($self->get('To'), $self->get('Cc'))) 
        {   my $lc   = lc $addr->address;
            $cc{$lc} = $addr->format
                 unless $nocc{$lc};
        }
        my $cc = join ', ', values %cc;
        $reply->replace(Cc => $cc);
    }

    # References
    my $refs    = $self->get('References') || "";
    my $mid     = $self->get('Message-Id');

    $refs      .= " " . $mid if defined $mid;
    $reply->replace(References => $refs);

    # In-Reply-To
    my $date    = $self->get('Date');
    my $inreply = "";

    if(defined $mid)
    {    $inreply  = $mid;
         my @comment;
         push @comment, "from $name" if defined $name;
         push @comment, "on $date"   if defined $date;
         local $"  = ' ';
         $inreply .= " (@comment)"   if @comment;
    }
    elsif(defined $name)
    {    $inreply  = $name    . "'s message";
         $inreply .= "of "    . $date if defined $date;
    }
    $reply->replace('In-Reply-To' => $inreply);

    # Quote the body
    my $body  = $reply->body;
    @$body = @{$self->body};    # copy body
    $reply->remove_sig;
    $reply->tidy_body;
    s/\A/$indent/ for @$body;

    # Add references
    unshift @{$body}, (defined $name ? $name . " " : "") . "<$id> writes:\n";

    if(defined $arg{Keep} && ref $arg{Keep} eq 'ARRAY')      # Include lines
    {   foreach my $keep (@{$arg{Keep}}) 
        {    my $ln = $self->get($keep);
             $reply->replace($keep => $ln) if defined $ln;
        }
    }

    if(defined $arg{Exclude} && ref $arg{Exclude} eq 'ARRAY') # Exclude lines
    {    $reply->delete(@{$arg{Exclude}});
    }

    $reply->head->cleanup;      # remove empty header lines
    $reply;
}


sub smtpsend($@)
{   my ($self, %opt) = @_;

    require Net::SMTP;
    require Net::Domain;

    my $host     = $opt{Host};
    my $envelope = $opt{MailFrom} || mailaddress();
    my $quit     = 1;

    my ($smtp, @hello);

    push @hello, Hello => $opt{Hello}
        if defined $opt{Hello};

    push @hello, Port => $opt{Port}
	if exists $opt{Port};

    push @hello, Debug => $opt{Debug}
	if exists $opt{Debug};

    if(!defined $host)
    {   local $SIG{__DIE__};
	my @hosts = qw(mailhost localhost);
	unshift @hosts, split /\:/, $ENV{SMTPHOSTS}
            if defined $ENV{SMTPHOSTS};

	foreach $host (@hosts)
        {   $smtp = eval { Net::SMTP->new($host, @hello) };
	    last if defined $smtp;
	}
    }
    elsif(UNIVERSAL::isa($host,'Net::SMTP')
       || UNIVERSAL::isa($host,'Net::SMTP::SSL'))
    {   $smtp = $host;
	$quit = 0;
    }
    else
    {   local $SIG{__DIE__};
	$smtp = eval { Net::SMTP->new($host, @hello) };
    }

    defined $smtp or return ();

    my $head = $self->cleaned_header_dup;

    # Who is it to

    my @rcpt = map { ref $_ ? @$_ : $_ } grep { defined } @opt{'To','Cc','Bcc'};
    @rcpt    = map { $head->get($_) } qw(To Cc Bcc)
	unless @rcpt;

    my @addr = map {$_->address} Mail::Address->parse(@rcpt);
    @addr or return ();

    $head->delete('Bcc');

    # Send it

    my $ok = $smtp->mail($envelope)
          && $smtp->to(@addr)
          && $smtp->data(join("", @{$head->header}, "\n", @{$self->body}));

    $quit && $smtp->quit;
    $ok ? @addr : ();
}


sub send($@)
{   my ($self, $type, @args) = @_;

    require Mail::Mailer;

    my $head  = $self->cleaned_header_dup;
    my $mailer = Mail::Mailer->new($type, @args);

    $mailer->open($head->header_hashref);
    $self->print_body($mailer);
    $mailer->close;
}


sub nntppost
{   my ($self, %opt) = @_;

    require Net::NNTP;

    my $groups = $self->get('Newsgroups') || "";
    my @groups = split /[\s,]+/, $groups;
    @groups or return ();

    my $head   = $self->cleaned_header_dup;

    # Remove these incase the NNTP host decides to mail as well as me
    $head->delete(qw(To Cc Bcc)); 

    my $news;
    my $quit   = 1;

    my $host   = $opt{Host};
    if(ref($host) && UNIVERSAL::isa($host,'Net::NNTP'))
    {   $news = $host;
	$quit = 0;
    }
    else
    {   my @opt = $opt{Host};

	push @opt, Port => $opt{Port}
	    if exists $opt{Port};

	push @opt, Debug => $opt{Debug}
	    if exists $opt{Debug};

	$news = Net::NNTP->new(@opt)
	    or return ();
    }

    $news->post(@{$head->header}, "\n", @{$self->body});
    my $rc = $news->code;

    $news->quit if $quit;

    $rc == 240 ? @groups : ();
}


sub escape_from
{   my $body = shift->body;
    scalar grep { s/\A(>*From) />$1 /o } @$body;
}



sub unescape_from
{   my $body = shift->body;
    scalar grep { s/\A>(>*From) /$1 /o } @$body;
}

# Don't tell people it exists
sub cleaned_header_dup()
{   my $head = shift->head->dup;

    $head->delete('From '); # Just in case :-)

    # An original message should not have any Received lines
    $head->delete('Received');

    $head->replace('X-Mailer', "Perl5 Mail::Internet v".$Mail::Internet::VERSION)
        unless $head->count('X-Mailer');

    my $name = eval {local $SIG{__DIE__}; (getpwuid($>))[6]} || $ENV{NAME} ||"";

    while($name =~ s/\([^\(\)]*\)//) { 1; }

    if($name =~ /[^\w\s]/)
    {   $name =~ s/"/\"/g;
	$name = '"' . $name . '"';
    }

    my $from = sprintf "%s <%s>", $name, mailaddress();
    $from =~ s/\s{2,}/ /g;

    foreach my $tag (qw(From Sender))
    {   $head->get($tag) or $head->add($tag, $from);
    }

    $head;
}

1;
