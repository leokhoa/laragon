# Copyright (c) 2002 Graham Barr <gbarr@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Authen::SASL::CRAM_MD5;
$Authen::SASL::CRAM_MD5::VERSION = '2.1700';
use strict;
use warnings;


sub new {
  shift;
  Authen::SASL->new(@_, mechanism => 'CRAM-MD5');
}

1;

