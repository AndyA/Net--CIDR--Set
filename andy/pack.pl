#!/usr/bin/env perl

use strict;
use warnings;
use Data::Hexdumper qw( hexdump );

my $num = pack 'N', 0x1234567;
print hexdump( data => $num );
my $orig = unpack 'N', $num;
printf "0x%x\n", $orig;

# vim:ts=2:sw=2:sts=2:et:ft=perl

