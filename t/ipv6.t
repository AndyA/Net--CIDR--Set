#!perl

use strict;
use warnings;
use Test::More tests => 3;
use Net::CIDR::Set;

{
  ok my $set = eval { Net::CIDR::Set->new( '2001:0db8:1234::/48' ) }, 'parsed';
  ok !$@, 'no error';
  my @r   = $set->as_range_array( 2 );
  is_deeply [@r], ['2001:db8:1234::-2001:db8:1234:ffff:ffff:ffff:ffff:ffff'], 'range';
}

#For example, a network is denoted by the first address in the network and the bit block size of the prefix, such as 2001:0db8:1234::/48. The network starts at address 2001:0db8:1234:0000:0000:0000:0000:0000 and ends at 2001:0db8:1234:ffff:ffff:ffff:ffff:ffff.

# vim:ts=2:sw=2:et:ft=perl

