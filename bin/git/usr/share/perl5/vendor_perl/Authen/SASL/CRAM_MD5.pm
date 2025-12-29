# Copyright (c) 2002 Graham Barr <gbarr@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Authen::SASL::CRAM_MD5 2.1900;

use strict;
use warnings;

warnings::warnif(
    'deprecated',
    'The CRAM-MD5 SASL mechanism is effectively deprecated by RFC8314 and should no longer be used'
    );

sub new {
  shift;
  Authen::SASL->new(@_, mechanism => 'CRAM-MD5');
}

1;

