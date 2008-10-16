#!/usr/bin/perl -w
#
#  t
#
#  Created by Andy Armstrong on 2008-12-19.
#  Copyright (c) 2008 Hexten. All rights reserved.

use strict;
use lib qw(lib);
use Net::CIDR::Set;
use Data::Dumper;

$| = 1;

my $set = Net::CIDR::Set->new();

$set->add(1, 3, 5, 7, 9);
$set->add_range(100, 1_000_000);
print $set->as_string(), "\n";

# $set->add_range(5, 7);
# print Dumper($set->_edges());
# $set->add_range(1, 3);
# print Dumper($set->_edges());
# $set->add_range(11, 100);
# print Dumper($set->_edges());
# $set->add(0);
# print Dumper($set->_edges());
