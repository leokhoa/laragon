# Copyright (c) 2002 Graham Barr <gbarr@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Authen::SASL::CRAM_MD5;

use strict;
use vars qw($VERSION);

$VERSION = "2.14";

sub new {
  shift;
  Authen::SASL->new(@_, mechanism => 'CRAM-MD5');
}

1;

