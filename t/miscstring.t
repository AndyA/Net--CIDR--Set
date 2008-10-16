use strict;
use warnings;
use Test::More tests => 3;
use Net::CIDR::Set;

ok my $set = Net::CIDR::Set->new(), 'create OK';

$set->add_from_string( '1,4-5,100-200' );
is $set->as_string, '1,4-5,100-200', 'add OK';
$set->remove_from_string( '150-180' );
is $set->as_string, '1,4-5,100-149,181-200', 'remove OK';
