#!perl

use strict;
use warnings;
use Test::More tests => 4;
use Net::CIDR::Set;

{
  ok my $set = Net::CIDR::Set->new, "set created OK";
  isa_ok $set, 'Net::CIDR::Set';
  $set->add('127.0.0.1');
  isa_ok $set, 'Net::CIDR::Set';
  isa_ok $set, 'Net::CIDR::Set::IPv4';
}

# vim:ts=2:sw=2:et:ft=perl

