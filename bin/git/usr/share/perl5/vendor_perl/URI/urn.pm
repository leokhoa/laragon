package URI::urn;  # RFC 2141

use strict;
use warnings;

our $VERSION = '5.21';

use parent 'URI';

use Carp qw(carp);

my %implementor;
my %require_attempted;

sub _init {
    my $class = shift;
    my $self = $class->SUPER::_init(@_);
    my $nid = $self->nid;

    my $impclass = $implementor{$nid};
    return $impclass->_urn_init($self, $nid) if $impclass;

    $impclass = "URI::urn";
    if ($nid =~ /^[A-Za-z\d][A-Za-z\d\-]*\z/) {
	my $id = $nid;
	# make it a legal perl identifier
	$id =~ s/-/_/g;
	$id = "_$id" if $id =~ /^\d/;

	$impclass = "URI::urn::$id";
	no strict 'refs';
	unless (@{"${impclass}::ISA"}) {
            if (not exists $require_attempted{$impclass}) {
                # Try to load it
                my $_old_error = $@;
                eval "require $impclass";
                die $@ if $@ && $@ !~ /Can\'t locate.*in \@INC/;
                $@ = $_old_error;
            }
	    $impclass = "URI::urn" unless @{"${impclass}::ISA"};
	}
    }
    else {
	carp("Illegal namespace identifier '$nid' for URN '$self'") if $^W;
    }
    $implementor{$nid} = $impclass;

    return $impclass->_urn_init($self, $nid);
}

sub _urn_init {
    my($class, $self, $nid) = @_;
    bless $self, $class;
}

sub _nid {
    my $self = shift;
    my $opaque = $self->opaque;
    if (@_) {
	my $v = $opaque;
	my $new = shift;
	$v =~ s/[^:]*/$new/;
	$self->opaque($v);
	# XXX possible rebless
    }
    $opaque =~ s/:.*//s;
    return $opaque;
}

sub nid {  # namespace identifier
    my $self = shift;
    my $nid = $self->_nid(@_);
    $nid = lc($nid) if defined($nid);
    return $nid;
}

sub nss {  # namespace specific string
    my $self = shift;
    my $opaque = $self->opaque;
    if (@_) {
	my $v = $opaque;
	my $new = shift;
	if (defined $new) {
	    $v =~ s/(:|\z).*/:$new/;
	}
	else {
	    $v =~ s/:.*//s;
	}
	$self->opaque($v);
    }
    return undef unless $opaque =~ s/^[^:]*://;
    return $opaque;
}

sub canonical {
    my $self = shift;
    my $nid = $self->_nid;
    my $new = $self->SUPER::canonical;
    return $new if $nid !~ /[A-Z]/ || $nid =~ /%/;
    $new = $new->clone if $new == $self;
    $new->nid(lc($nid));
    return $new;
}

1;
