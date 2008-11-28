#!/usr/bin/env perl

use strict;
use warnings;
use lib qw(lib);
use Net::CIDR::Set;

my $set = Net::CIDR::Set->new( '127.0.0.1', '192.168.37.0/24',
  '10.0.0.11-10.0.0.17' );

for my $fmt ( 0 .. 2 ) {
  print "Using format $fmt:\n";
  print "  $_\n" for $set->as_range_array( $fmt );
}

my $set
 = Net::CIDR::Set->new( '192.168.37.9-192.168.37.134', '127.0.0.1',
  '10.0.0.0/8' );
my $iter = $set->iterate_ranges;
while ( my $range = $iter->() ) {
  print "Got $range\n";
}

# vim:ts=2:sw=2:sts=2:et:ft=perl

