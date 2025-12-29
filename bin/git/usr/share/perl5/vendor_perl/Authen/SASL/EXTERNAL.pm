# Copyright (c) 2002 Graham Barr <gbarr@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Authen::SASL::EXTERNAL 2.1900;

use strict;
use warnings;


sub new {
  shift;
  Authen::SASL->new(@_, mechanism => 'EXTERNAL');
}

1;

