#!perl

use strict;
use warnings;
use Test::More tests => 3;
use Net::CIDR::Set;

{
  ok my $set = eval { Net::CIDR::Set->new( '2001:0db8:1234::/48' ) },
   'parsed';
  ok !$@, 'no error';
  my @r = $set->as_range_array( 2 );
  is_deeply [@r],
   ['2001:db8:1234::-2001:db8:1234:ffff:ffff:ffff:ffff:ffff'], 'range';
}

# vim:ts=2:sw=2:et:ft=perl

