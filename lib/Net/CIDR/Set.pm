package Net::CIDR::Set;

use warnings;
use strict;
use Carp;
use Data::Types qw(is_int);
use List::Util qw(min max);

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

=head2 C<< pack >>

Pack an IPv4 or IPv6 address into our internal bit vector format.

=cut

sub encode {
  my $self = shift;
  my $ip   = shift;
  if ( _pack_ipv4( $ip ) ) {
    bless $self, 'Net::CIDR::Set::IPv4';
  }
  elsif ( _pack_ipv6( $ip ) ) {
    bless $self, 'Net::CIDR::Set::IPv6';
  }
  else {
    croak "Can't parse address $ip";
  }
  return $self->encode( $ip );
}

sub _nbits {
  croak "Please add an address so I know what "
   . "kind of data I'm dealing with";
}

*decode = *_nbits;

# IPv4

sub _pack_ipv4 {
  my $self = shift;
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

# IPv6

sub _pack_ipv6 {
  my $self = shift;
  my $ip   = shift;
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

sub add {
  my $self = shift;
  $self->add_range( $self->_list_to_ranges( @_ ) );
}

sub remove {
  my $self = shift;
  $self->remove_range( $self->_list_to_ranges( @_ ) );
}

sub add_range {
  my $self = shift;

  $self->_iterate_ranges(
    @_,
    sub {
      my ( $from, $to ) = @_;

      my $fpos = $self->_find_pos( $from );
      # TODO: Maths?
      my $tpos = $self->_find_pos( _pack( _unpack( $to ) + 1 ), $fpos );

      $from = $self->{ranges}[ --$fpos ] if ( $fpos & 1 );
      $to   = $self->{ranges}[ $tpos++ ] if ( $tpos & 1 );

      splice @{ $self->{ranges} }, $fpos, $tpos - $fpos, ( $from, $to );
    }
  );
}

sub add_from_string {
  my $self = shift;

  my $ctl          = {};
  my $match_number = qr/\s* (-?\d+) \s*/x;
  my $match_single = qr/^ $match_number $/x;
  my $match_range;

  my @to_add = ();

  # Iterate args. Default punctuation spec prepended.
  for my $el ( { sep => qr/,/, range => qr/-/, }, @_ ) {

    # Allow parsing options to be set.
    if ( 'HASH' eq ref $el ) {
      %$ctl = ( %$ctl, %$el );
      for ( values %$ctl ) {
        $_ = quotemeta( $_ ) unless ref $_ eq 'Regexp';
      }
      $match_range = qr/^ $match_number $ctl->{range} $match_number $/x;
    }
    else {
      for my $part ( split $ctl->{sep}, $el ) {
        if ( my ( $start, $end ) = ( $part =~ $match_range ) ) {
          push @to_add, $start, $end;
        }
        elsif ( my ( $el ) = ( $part =~ $match_single ) ) {
          push @to_add, $el, $el;
        }
        else {
          croak "Invalid range string"
           unless $part =~ $match_single;
        }
      }
    }
  }

  $self->add_range( @to_add );
}

sub remove_range {
  my $self = shift;

  $self->invert;
  $self->add_range( @_ );
  $self->invert;
}

sub remove_from_string {
  my $self = shift;

  $self->invert;
  $self->add_from_string( @_ );
  $self->invert;
}

sub merge {
  my $self = shift;

  for my $other ( @_ ) {
    my $iter = $other->iterate_runs;
    while ( my ( $from, $to ) = $iter->() ) {
      $self->add_range( $from, $to );
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

sub cardinality {
  my $self = shift;

  my $card = 0;
  my $iter = $self->iterate_runs( @_ );
  while ( my ( $from, $to ) = $iter->() ) {
    $card += $to - $from + 1;
  }

  return $card;
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

sub as_array {
  my $self = shift;
  my @ar   = ();
  my $iter = $self->iterate_runs;
  while ( my ( $from, $to ) = $iter->() ) {
    push @ar, ( $from .. $to );
  }

  return @ar;
}

sub as_string {
  my $self = shift;
  my $ctl = { sep => ',', range => '-' };
  %$ctl = ( %$ctl, %{ $_[0] } ) if @_;
  my $iter = $self->iterate_runs;
  my @runs = ();
  while ( my ( $from, $to ) = $iter->() ) {
    push @runs,
     $from eq $to ? $from : join( $ctl->{range}, $from, $to );
  }
  return join( $ctl->{sep}, @runs );
}

sub iterate_runs {
  my $self = shift;

  if ( @_ ) {

    # Clipped iterator
    my ( $clip_lo, $clip_hi ) = map { _pack( $_ ) } @_;

    my $pos = $self->_find_pos( $clip_lo ) & ~1;
    my $limit
     = (
      $self->_find_pos( _pack( _unpack( $clip_hi ) + 1 ), $pos ) + 1 )
     & ~1;

    return sub {
      TRY: {
        return if $pos >= $limit;

        # TODO: Maths
        my @r = (
          $self->{ranges}[$pos],
          _pack( _unpack( $self->{ranges}[ $pos + 1 ] ) - 1 )
        );
        $pos += 2;

        # Catch some edge cases
        redo TRY if $r[1] lt $clip_lo;
        return   if $r[0] gt $clip_hi;

        # Clip to range
        $r[0] = $clip_lo if $r[0] lt $clip_lo;
        $r[1] = $clip_hi if $r[1] gt $clip_hi;

        return map { _unpack( $_ ) } @r;
      }
    };
  }
  else {

    # Unclipped iterator
    my $pos   = 0;
    my $limit = scalar( @{ $self->{ranges} } );

    return sub {
      return if $pos >= $limit;
      my @r = (
        _unpack( $self->{ranges}[$pos] ),
        _unpack( $self->{ranges}[ $pos + 1 ] ) - 1
      );
      $pos += 2;
      return @r;
    };
  }

}

sub _list_to_ranges {
  my $self   = shift;
  my @list   = sort { $a <=> $b } @_;
  my @ranges = ();
  my $count  = scalar( @list );
  my $pos    = 0;
  while ( $pos < $count ) {
    my $end = $pos + 1;
    $end++ while $end < $count && $list[$end] le $list[ $end - 1 ] + 1;
    push @ranges, ( $list[$pos], $list[ $end - 1 ] );
    $pos = $end;
  }

  return @ranges;
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

  my $count = scalar( @_ );

  croak "Range list must have an even number of elements"
   if ( $count % 2 ) != 0;

  for ( my $p = 0; $p < $count; $p += 2 ) {
    my ( $from, $to ) = ( $_[$p], $_[ $p + 1 ] );
    croak "Range limits must be integers"
     unless is_int( $from ) && is_int( $to );
    croak "Range limits must be in ascending order"
     unless $from <= $to;
    #croak "Value out of range"
    #unless $from >= NEGATIVE_INFINITY && $to <= POSITIVE_INFINITY;

    # Internally we store inclusive/exclusive ranges to
    # simplify comparisons, hence '$to + 1'
    $cb->( _pack( $from ), _pack( $to + 1 ) );
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
