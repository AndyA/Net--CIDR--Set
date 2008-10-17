#!perl

use strict;
use warnings;
use Test::More tests => 143;
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
    is unpack( 'N', Net::CIDR::Set::_dec( pack 'N', $n ) ), $p,
     "_dec($n) == $p";
    is unpack( 'N', Net::CIDR::Set::_dec( pack 'N', $q ) ), $n,
     "_dec($q) == $n";
  }
  my @big = (
    {
      name   => '0 to 1',
      before => [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
      after  => [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 ]
    },
    {
      name => 'wrap some',
      before =>
       [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 255, 255, 255, 255 ],
      after => [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0 ]
    },
    {
      name   => 'wrap all',
      before => [
        255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255
      ],
      after => [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]
    },
  );
  for my $b ( @big ) {
    my $name = $b->{name};
    my @inc  = unpack 'C*',
     Net::CIDR::Set::_inc( pack 'C*', @{ $b->{before} } );
    is_deeply [@inc], $b->{after}, "$name: _inc";
    my @dec = unpack 'C*', Net::CIDR::Set::_dec( pack 'C*', @inc );
    is_deeply [@dec], $b->{before}, "$name: _dec";
  }
}

{
  # _decode_ipv4
  my @case = (
    {
      ip     => '127.0.0.1',
      expect => [ [ 0, 127, 0, 0, 1 ], [ 0, 127, 0, 0, 2 ] ]
    },
    {
      ip     => '192.168.0.0/16',
      expect => [ [ 0, 192, 168, 0, 0 ], [ 0, 192, 169, 0, 0 ] ]
    },
    {
      ip     => '192.168.0.0/255.255.0.0',
      expect => [ [ 0, 192, 168, 0, 0 ], [ 0, 192, 169, 0, 0 ] ]
    },
    {
      ip     => '192.168.0.0/0.0.255.255',
      expect => []                           # error
    },
    {
      ip     => '0.0.0.0/0',
      expect => [ [ 0, 0, 0, 0, 0 ], [ 1, 0, 0, 0, 0 ] ]
    },
    {
      ip     => '192.168.0.12-192.168.1.13',
      expect => [ [ 0, 192, 168, 0, 12 ], [ 0, 192, 168, 1, 14 ] ]
    },
    {
      ip     => '0.0.0.0-255.255.255.255',
      expect => [ [ 0, 0, 0, 0, 0 ], [ 1, 0, 0, 0, 0 ] ]
    },
  );
  for my $case ( @case ) {
    my @got = map { [ unpack 'C*', $_ ] }
     Net::CIDR::Set->_decode_ipv4( $case->{ip} );
    is_deeply [@got], $case->{expect}, "decode $case->{ip}";
  }
}

{
  # _encode_ipv4

  my @case = (
    {
      range => [ [ 0, 192, 168, 0, 12 ], [ 0, 192, 168, 1, 14 ] ],
      expect => '192.168.0.12-192.168.1.13',
    },
    {
      range => [ [ 0, 0, 0, 0, 0 ], [ 1, 0, 0, 0, 0 ] ],
      expect => '0.0.0.0-255.255.255.255',
    },
  );
  for my $case ( @case ) {
    my $got = Net::CIDR::Set->_encode_ipv4( map { pack 'C*', @$_ }
       @{ $case->{range} } );
    is $got, $case->{expect}, "$got";
  }
}

# vim:ts=2:sw=2:et:ft=perl
