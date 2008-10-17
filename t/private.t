#!perl

use strict;
use warnings;
use Test::More tests => 64;
use Net::CIDR::Set;

{
  # _inc
  for my $b ( 0 .. 31 ) {
    my $n = 1 << $b;
    my $p = $n - 1;
    my $q = $n + 1;
    is unpack( 'N', Net::CIDR::Set::_inc( pack 'N', $p ) ), $n,
     "_inc($p) == $n";
    is unpack( 'N', Net::CIDR::Set::_inc( pack 'N', $n ) ), $q,
     "_inc($n) == $q";
  }
}

# vim:ts=2:sw=2:et:ft=perl

