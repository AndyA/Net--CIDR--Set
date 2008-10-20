package Net::CIDR::Set;

use warnings;
use strict;
use Carp qw( croak confess );
use Net::CIDR::Set::IPv4;
use Net::CIDR::Set::IPv6;

=head1 NAME

Net::CIDR::Set - Manipulate sets of IP addresses

=head1 VERSION

This document describes Net::CIDR::Set version 0.10

=head1 SYNOPSIS

  use Net::CIDR::Set;

  my $priv = Net::CIDR::Set->new( '10.0.0.0/8', '172.16.0.0/12',
    '192.168.0.0/16' );
  for my $ip ( @addr ) {
    if ( $priv->contains( $ip ) ) {
      print "$ip is private\n";
    }
  }

=head2 DESCRIPTION

C<Net::CIDR::Set> represents sets of IP addresses and allows standard
set operations (union, intersection, membership test etc) to be
performed on them.

In spite of the name it can work with sets consisting of arbitrary
ranges of IP addresses - not just CIDR blocks.

=cut

our $VERSION = '0.10';

sub new {
  my $class = shift;
  my $self = bless { ranges => [] }, $class;
  $self->add( @_ ) if @_;
  return $self;
}

# Return the index of the first element >= the supplied value. If the
# supplied value is larger than any element in the list the returned
# value will be equal to the size of the list.
sub _find_pos {
  my $self = shift;
  my $val  = shift;
  my $low  = shift || 0;

  my $high = scalar( @{ $self->{ranges} } );

  while ( $low < $high ) {
    my $mid = int( ( $low + $high ) / 2 );
    my $cmp = $val cmp $self->{ranges}[$mid];
    if ( $cmp < 0 ) {
      $high = $mid;
    }
    elsif ( $cmp > 0 ) {
      $low = $mid + 1;
    }
    else {
      return $mid;
    }
  }

  return $low;
}

sub _inc {
  my @b = reverse unpack 'C*', shift;
  for ( @b ) {
    last unless ++$_ == 256;
    $_ = 0;
  }
  return pack 'C*', reverse @b;
}

sub _dec {
  my @b = reverse unpack 'C*', shift;
  for ( @b ) {
    last unless $_-- == 0;
    $_ = 255;
  }
  return pack 'C*', reverse @b;
}

sub _encode {
  my $self = shift;
  my $ip   = shift;
  if ( $self->_encode_ipv4( $ip ) ) {
    bless $self, 'Net::CIDR::Set::IPv4';
  }
  elsif ( $self->_encode_ipv6( $ip ) ) {
    bless $self, 'Net::CIDR::Set::IPv6';
  }
  else {
    # TODO: Error handling after rebless?
    croak "Can't parse address $ip";
  }
  return $self->_encode( $ip );
}

sub _nbits {
  croak "Please add an address so I know what "
   . "kind of data I'm dealing with";
}

*_decode = *_nbits;

# IPv4

sub _pack_ipv4 {
  my @nums = split /[.]/, shift, -1;
  return unless @nums == 4;
  for ( @nums ) {
    return unless /^\d{1,3}$/ and $_ < 256;
  }
  return pack "CC*", 0, @nums;
}

sub _unpack_ipv4 { join ".", unpack "xC*", shift }

sub _width2bits {
  my ( $width, $size ) = @_;
  return pack 'B*',
   ( '1' x ( $width + 8 ) ) . ( '0' x ( $size - $width ) );
}

sub _ip2bits {
  my $ip = shift or return;
  vec( $ip, 0, 8 ) = 255;
  my $bits = unpack 'B*', $ip;
  return unless $bits =~ /^1*0*$/;    # Valid mask?
  return $ip;
}

sub _encode_ipv4 {
  my ( $self, $ip ) = @_;
  if ( $ip =~ m{^(.+?)/(.+)$} ) {
    return unless my $addr = _pack_ipv4( $1 );
    my $mask = $2;
    return
     unless my $bits
       = ( $mask =~ /^\d+$/ )
      ? _width2bits( $mask, 32 )
      : _ip2bits( _pack_ipv4( $mask ) );
    return ( $addr & $bits, _inc( $addr | ~$bits ) );
  }
  elsif ( $ip =~ m{^(.+?)-(.+)$} ) {
    return unless my $lo = _pack_ipv4( $1 );
    return unless my $hi = _pack_ipv4( $2 );
    return ( $lo, _inc( $hi ) );
  }
  else {
    return $self->_encode_ipv4( "$ip/32" );
  }
}

sub _is_cidr {
  my ( $lo, $hi ) = @_;
  my $mask = ~( $lo ^ $hi );
  my $bits = unpack 'B*', $mask;
  return unless $bits =~ /^(1*)0*$/;
  return length( $1 ) - 8;
}

sub _decode_ipv4 {
  my $self    = shift;
  my $lo      = shift;
  my $hi      = _dec( shift );
  my $generic = shift || 0;
  if ( $generic < 1 && $lo eq $hi ) {
    # Single address
    return _unpack_ipv4( $lo );
  }
  elsif ( $generic < 2 && defined( my $w = _is_cidr( $lo, $hi ) ) ) {
    # Valid CIDR range
    return join '/', _unpack_ipv4( $lo ), $w;
  }
  else {
    # General range
    return join '-', _unpack_ipv4( $lo ), _unpack_ipv4( $hi );
  }
}

# IPv6

sub _pack_ipv6 {
  my $ip = shift;
  return if $ip =~ /^:/ and $ip !~ s/^::/:/;
  return if $ip =~ /:$/ and $ip !~ s/::$/:/;
  my @nums = split /:/, $ip, -1;
  return unless @nums <= 8;
  my ( $empty, $ipv4, $str ) = ( 0, '', '' );
  for ( @nums ) {
    return if $ipv4;
    $str .= "0" x ( 4 - length ) . $_, next if /^[a-fA-F\d]{1,4}$/;
    do { return if $empty++ }, $str .= "X", next if $_ eq '';
    next if $ipv4 = _pack_ipv4( $_ );
    return;
  }
  return if $ipv4 and @nums > 6;
  $str =~ s/X/"0" x (($ipv4 ? 25 : 33)-length($str))/e if $empty;
  return pack( "H*", "00" . $str ) . $ipv4;
}

sub _unpack_ipv6 {
  return _compress_ipv6(
    join( ":", unpack( "xH*", shift ) =~ /..../g ) );
}

# Replace longest run of null blocks with a double colon
sub _compress_ipv6 {
  my $ip = shift;
  if ( my @runs = $ip =~ /((?:(?:^|:)(?:0000))+:?)/g ) {
    my $max = $runs[0];
    for ( @runs[ 1 .. $#runs ] ) {
      $max = $_ if length( $max ) < length;
    }
    $ip =~ s/$max/::/;
  }
  $ip =~ s/:0{1,3}/:/g;
  return $ip;
}

sub _encode_ipv6 {
  my ( $self, $ip ) = @_;
  confess "Can't do IPv6 yet";
}

sub _decode_ipv6 {
  my ( $self, $lo, $hi ) = @_;
  confess "Can't do IPv6 yet";
}

sub _rebless_and_check {
  my ( $self, @others ) = @_;
  my $pkg   = __PACKAGE__;
  my %class = ();
  $class{$_}++ for map ref, $self, @others;
  delete $class{$pkg};
  my @found = sort keys %class;
  croak "Can't mix ", $self->_conjunction( and => @found )
   if @found > 1;
  bless $self, $found[0] if $pkg eq ref $self;
  return $self;
}

sub invert {
  my $self = shift;

  my @pad = ( 0 ) x ( $self->_nbits / 8 );
  my ( $min, $max ) = map { pack 'C*', $_, @pad } 0, 1;

  if ( $self->is_empty ) {
    $self->{ranges} = [ $min, $max ];
    return;
  }

  if ( $self->{ranges}[0] eq $min ) {
    shift @{ $self->{ranges} };
  }
  else {
    unshift @{ $self->{ranges} }, $min;
  }

  if ( $self->{ranges}[-1] eq $max ) {
    pop @{ $self->{ranges} };
  }
  else {
    push @{ $self->{ranges} }, $max;
  }
}

sub copy {
  my $self  = shift;
  my $class = ref $self;
  my $copy  = $class->new;
  @{ $copy->{ranges} } = @{ $self->{ranges} };
  return $copy;
}

sub _add_range {
  my ( $self, $from, $to ) = @_;
  my $fpos = $self->_find_pos( $from );
  my $tpos = $self->_find_pos( $to, $fpos );

  $from = $self->{ranges}[ --$fpos ] if ( $fpos & 1 );
  $to   = $self->{ranges}[ $tpos++ ] if ( $tpos & 1 );

  splice @{ $self->{ranges} }, $fpos, $tpos - $fpos, ( $from, $to );
}

sub add {
  my ( $self, @addr ) = @_;
  for my $ip ( @addr ) {
    my ( $lo, $hi ) = $self->_encode( $ip )
     or croak "Can't parse $ip";
    $self->_add_range( $lo, $hi );
  }
}

sub remove {
  my $self = shift;

  $self->invert;
  $self->add( @_ );
  $self->invert;
}

*contains = *contains_all;

sub contains_any {
  my $self  = shift;
  my $class = ref $self;
  return !$class->new( @_ )->intersection( $self )->is_empty;
}

sub contains_all {
  my $self  = shift;
  my $class = ref $self;
  my $want  = $class->new( @_ );
  return $want->intersection( $self )->equals( $want );
}

sub _iterate_runs {
  my $self = shift;

  my $pos   = 0;
  my $limit = scalar( @{ $self->{ranges} } );

  return sub {
    return if $pos >= $limit;
    my @r = @{ $self->{ranges} }[ $pos, $pos + 1 ];
    $pos += 2;
    return @r;
  };
}

sub iterate_addresses {
  my ( $self, @args ) = @_;
  my $iter = $self->_iterate_runs;
  my @r    = ();
  return sub {
    while ( 1 ) {
      @r = $iter->() or return unless @r;
      return $self->_decode( ( my $last, $r[0] )
        = ( $r[0], _inc( $r[0] ) ), @args )
       unless $r[0] eq $r[1];
      @r = ();
    }
  };
}

sub iterate_cidr {
  my ( $self, @args ) = @_;
  my $iter = $self->_iterate_runs;
  my @r    = ();
  return sub {
    while ( 1 ) {
      @r = $iter->() or return unless @r;
      unless ( $r[0] eq $r[1] ) {
        ( my $bits = unpack 'B*', $r[0] ) =~ /(0*)$/;
        my $pad = length $1;
        while ( 1 ) {
          my $next = _inc( $r[0] | pack 'B*',
            ( '0' x ( length( $bits ) - $pad ) ) . ( '1' x $pad ) );
          return $self->_decode( ( my $last, $r[0] ) = ( $r[0], $next ),
            @args )
           if $next le $r[1];
          $pad--;
        }
      }
      @r = ();
    }
  };
}

sub iterate_ranges {
  my ( $self, @args ) = @_;
  my $iter = $self->_iterate_runs;
  return sub {
    return unless my @r = $iter->();
    return $self->_decode( @r, @args );
  };
}

sub as_array {
  my ( $self, $iter ) = @_;
  my @addr = ();
  while ( my $addr = $iter->() ) {
    push @addr, $addr;
  }
  return @addr;
}

sub as_address_array {
  my $self = shift;
  return $self->as_array( $self->iterate_addresses( @_ ) );
}

sub as_cidr_array {
  my $self = shift;
  return $self->as_array( $self->iterate_cidr( @_ ) );
}

sub as_range_array {
  my $self = shift;
  return $self->as_array( $self->iterate_ranges( @_ ) );
}

sub _conjunction {
  my ( $self, $conj, @list ) = @_;
  my $last = pop @list;
  return join " $conj ", join( ', ', @list ), $last;
}

sub merge {
  my $self = shift;
  $self->_rebless_and_check( @_ );

  # TODO: This isn't very efficient - and merge gets called from all
  # sorts of other places.
  for my $other ( @_ ) {
    my $iter = $other->_iterate_runs;
    while ( my ( $from, $to ) = $iter->() ) {
      $self->_add_range( $from, $to );
    }
  }
}

sub compliment {
  croak "That's very kind of you - but I expect you meant complement";
}

sub complement {
  my $new = shift->copy;
  # TODO: What if it's empty?
  $new->invert;
  return $new;
}

sub union {
  my $new = shift->copy;
  $new->merge( @_ );
  return $new;
}

sub intersection {
  my $self  = shift;
  my $class = ref $self;
  my $new   = $class->new;
  $new->merge( map { $_->complement } $self, @_ );
  $new->invert;
  return $new;
}

sub xor {
  my $self = shift;
  return $self->union( @_ )
   ->intersection( $self->intersection( @_ )->complement );
}

sub diff {
  my $self  = shift;
  my $other = shift;
  return $self->intersection( $other->union( @_ )->complement );
}

sub is_empty {
  my $self = shift;
  return @{ $self->{ranges} } == 0;
}

sub superset {
  my $other = pop;
  return $other->subset( reverse( @_ ) );
}

sub subset {
  my $self = shift;
  my $other = shift || croak "I need two sets to compare";
  return $self->equals( $self->intersection( $other ) );
}

sub equals {
  return unless @_;

  # Array of array refs
  my @edges = map { $_->{ranges} } @_;
  my $medge = scalar( @edges ) - 1;

  POS: for ( my $pos = 0;; $pos++ ) {
    my $v = $edges[0]->[$pos];
    if ( defined( $v ) ) {
      for ( @edges[ 1 .. $medge ] ) {
        my $vv = $_->[$pos];
        return unless defined( $vv ) && $vv eq $v;
      }
    }
    else {
      for ( @edges[ 1 .. $medge ] ) {
        return if defined $_->[$pos];
      }
    }

    last POS unless defined( $v );
  }

  return 1;
}

1;

__END__

=head1 AUTHOR

Andy Armstrong  C<< <andy.armstrong@messagesystems.com> >>

=head1 CREDITS

The encode and decode routines were stolen en masse from Douglas
Wilson's L<Net::CIDR::Lite>.

=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

Copyright (c) 2008, Message Systems, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or
without modification, are permitted provided that the following
conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the
      distribution.
    * Neither the name Message Systems, Inc. nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
