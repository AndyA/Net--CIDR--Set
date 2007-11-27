#!/usr/bin/perl -w
#
#  t
#
#  Created by Andy Armstrong on 2006-12-19.
#  Copyright (c) 2006 Hexten. All rights reserved.

use strict;
use lib qw(lib);
use Set::IntSpan::Fast;
use Data::Dumper;

$| = 1;

my $set = Set::IntSpan::Fast->new();

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
