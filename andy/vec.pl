#!/usr/bin/env perl

use strict;
use warnings;

my @ar = (
  pack( 'CC*', 0, 3, 0, 0, 3 ),
  pack( 'CC*', 0, 2, 0, 0, 2 ),
  pack( 'CC*', 0, 1, 0, 0, 1 ),
  pack( 'CC*', 0, 3, 0, 0, 0 ),
  pack( 'CC*', 0, 2, 0, 0, 0 ),
  pack( 'CC*', 0, 1, 0, 0, 0 ),
);

my @so = sort { $a cmp $b } @ar;
for ( @so ) {
  print join ', ', unpack( 'C*', $_ ), "\n";
}

# vim:ts=2:sw=2:sts=2:et:ft=perl

