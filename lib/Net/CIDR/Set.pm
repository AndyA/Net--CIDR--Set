package Net::CIDR::Set;

use warnings;
use strict;
use Carp qw( croak confess );
use Net::CIDR::Set::IPv4;
use Net::CIDR::Set::IPv6;

=head1 NAME

Net::CIDR::Set - Pure Perl implementation.

=head1 VERSION

This document describes Net::CIDR::Set version 0.10

=cut

our $VERSION = '0.10';

sub new {
  my $class = shift;
  my $self = bless { ranges => [] }, $class;
  $self->add_from_string( @_ ) if @_;
  return $self;
}

sub _pack { pack 'N', shift }
sub _unpack { unpack 'N', shift }

# Hideously slow - but we don't do them often

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

=head2 C<< pack >>

Pack an IPv4 or IPv6 address into our internal bit vector format.

=cut

sub decode {
  my $self = shift;
  my $ip   = shift;
  if ( $self->_decode_ipv4( $ip ) ) {
    bless $self, 'Net::CIDR::Set::IPv4';
  }
  elsif ( -$self->_decode_ipv6( $ip ) ) {
    bless $self, 'Net::CIDR::Set::IPv6';
  }
  else {
    croak "Can't parse address $ip";
  }
  return $self->decode( $ip );
}

sub _nbits {
  croak "Please add an address so I know what "
   . "kind of data I'm dealing with";
}

*encode = *_nbits;

# IPv4

sub _pack_ipv4 {
  my @nums = split /\./, shift(), -1;
  return unless @nums == 4;
  for ( @nums ) {
    return unless /^\d{1,3}$/ and $_ <= 255;
  }
  return pack( "CC*", 0, @nums );
}

sub _unpack_ipv4 {
  return join( ".", unpack( "xC*", shift ) );
}

sub _width2bits {
  my ( $width, $size ) = @_;
  return pack 'b*',
   ( '1' x ( $width + 8 ) ) . ( '0' x ( $size - $width ) );
}

sub _set_top_byte {
  my @v = unpack 'C*', shift;
  $v[0] = 255;
  return pack 'C*', @v;
}

sub _ip2bits {
  my $ip = shift or return;
  $ip = _set_top_byte( $ip );
  my $bits = unpack 'b*', $ip;
  return unless $bits =~ /^1*0*$/;
  return $ip;
}

sub _decode_ipv4 {
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
    return $self->_decode_ipv4( "$ip/32" );
  }
}

sub _is_cidr {
  my ( $lo, $hi ) = @_;
  my $mask = ~( $lo ^ $hi );
  my $bits = unpack 'b*', $mask;
  return unless $bits =~ /^(1*)0*$/;
  return length( $1 ) - 8;
}

sub _encode_ipv4 {
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

sub _decode_ipv6 {
  my ( $self, $ip ) = @_;
  confess "Can't do IPv6 yet";
}

sub _encode_ipv6 {
  my ( $self, $lo, $hi ) = @_;
  confess "Can't do IPv6 yet";
}

sub invert {
  my $self = shift;

  my @pad = ( 0 ) x ( $self->_nbits / 8 );

  my ( $min, $max ) = map { pack 'C*', $_, @pad } 0, 1;

  if ( $self->is_empty ) {
    # Empty set
    $self->{ranges} = [ $min, $max ];
  }
  else {

    # Either add or remove infinity from each end. The net
    # effect is always an even number of additions and deletions
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
}

sub copy {
  my $self  = shift;
  my $class = ref $self;
  my $copy  = $class->new;
  # TODO: we can do better than this.
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
  my $self = shift;
  $self->_iterate_ranges( @_, sub { $self->_add_range( @_ ) } );
}

sub remove {
  my $self = shift;

  $self->invert;
  $self->add( @_ );
  $self->invert;
}

sub _iterate_runs {
  my $self = shift;

  my $pos   = 0;
  my $limit = scalar( @{ $self->{ranges} } );

  return sub {
    return if $pos >= $limit;
    my @r = ( $self->{ranges}[$pos], $self->{ranges}[ $pos + 1 ] );
    $pos += 2;
    return @r;
  };
}

sub iterate_addresses {
}

sub iterate_cidr {
}

sub iterate_ranges {
  my $self = shift;
  my $iter = $self->_iterate_runs;
  # Iterate ranges
  return sub {
    return unless my @r = $iter->();
    return $self->encode( @r, @_ );
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

sub merge {
  my $self = shift;

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

=for later

*contains = *contains_all;

sub contains_any {
  my $self = shift;

  for my $i ( @_ ) {
    my $pos = $self->_find_pos( _pack( $i + 1 ) );
    return 1 if $pos & 1;
  }

  return;
}

sub contains_all {
  my $self = shift;

  for my $i ( @_ ) {
    my $pos = $self->_find_pos( _pack( $i + 1 ) );
    return unless $pos & 1;
  }

  return 1;
}

sub contains_all_range {
  my $self = shift;
  my ( $lo, $hi ) = @_;

  croak "Range limits must be in ascending order" if $lo > $hi;

  my $pos = $self->_find_pos( _pack( $lo + 1 ) );
  return ( $pos & 1 ) && _pack( $hi ) lt $self->{ranges}[$pos];
}

=cut

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

## Please see file perltidy.ERR
## Please see file perltidy.ERR
## Please see file perltidy.ERR
## Please see file perltidy.ERR
## Please see file perltidy.ERR
## Please see file perltidy.ERR
## Please see file perltidy.ERR
sub as_array {
  my $self = shift;
  confess "Please write me";
}

sub as_string {
  my $self = shift;
  confess "Please write me";
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
    if ( $val lt $self->{ranges}[$mid] ) {
      $high = $mid;
    }
    elsif ( $val gt $self->{ranges}[$mid] ) {
      $low = $mid + 1;
    }
    else {
      return $mid;
    }
  }

  return $low;
}

sub _iterate_ranges {
  my $self = shift;
  my $cb   = pop;

  for my $ip ( @_ ) {
    my ( $lo, $hi ) = $self->decode( $ip )
     or croak "Can't parse $ip";
    $cb->( $lo, $hi );
  }
}

1;
__END__

=head1 AUTHOR

Andy Armstrong C<< <andy@hexten.net> >>

=head1 CREDITS

K. J. Cheetham L<< http://www.shadowcatsystems.co.uk/ >> for
add_from_string, remove_from_string. I butchered his code so any
errors are mine.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2008, Andy Armstrong C<< <andy@hexten.net> >>. All
rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL,
INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR
INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.
