#!/usr/bin/env perl

use strict;
use warnings;
use lib qw( lib );
use Benchmark qw( :hireswallclock :all );
use Net::CIDR::Set;

my @test_data = map { $_ * 37 } 1 .. 100_000;
my $set = Net::CIDR::Set->new;

timethese( 1,
    { map { case_for( $set, $_ * 2, \@test_data ) } 0 .. 15 } );

sub case_for {
    my ( $set, $offset, $data ) = @_;
    return sprintf( 'Set %04d', $offset ) => sub {
        $set->add( map { $_ + $offset } @$data );
        # print $set->cardinality, "\n";
    };
}
