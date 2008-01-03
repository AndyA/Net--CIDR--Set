package Set::IntSpan::Fast;

use warnings;
use strict;
use Carp;
use Data::Types qw(is_int);
use List::Util qw(min max);

=head1 NAME

Set::IntSpan::Fast - Fast handling of sets containing integer spans.

=head1 VERSION

This document describes Set::IntSpan::Fast version 1.11

=cut

use vars qw( $VERSION );
$VERSION = '1.11';

=head1 SYNOPSIS

    use Set::IntSpan::Fast;
    
    my $set = Set::IntSpan::Fast->new();
    $set->add(1, 3, 5, 7, 9);
    $set->add_range(100, 1_000_000);
    print $set->as_string(), "\n";    # prints 1,3,5,7,9,100-1000000

=head1 DESCRIPTION

C<Set::IntSpan::Fast> represents sets of integers. It is optimised for
sets that contain contiguous runs of values.

    1-1000, 2000-10000      # Efficiently handled

Sets that don't have this characteristic may still be represented but
some of the performance and storage space advantages will be lost.
Consider using bit vectors if your set does not typically contain
clusters of values.

Sets may be infinite - assuming you're prepared to accept that infinity
is actually no more than a fairly large integer. Specifically the
constants C<Set::IntSpan::Fast::NEGATIVE_INFINITY> and
C<Set::IntSpan::Fast::POSITIVE_INFINITY> are defined to be -(2^31-1) and
(2^31-2) respectively. To create an infinite set invert an empty one:

    my $inf = Set::IntSpan::Fast->new()->complement();

Sets need only be bounded in one direction - for example this is the set
of all positive integers (assuming you accept the slightly feeble
definition of infinity we're using):

    my $pos_int = Set::IntSpan::Fast->new();
    $pos_int->add_range(1, $pos_int->POSITIVE_INFINITY);

=head2 Set representation

The internal representation used is extremely simple: a set is
represented as a list of integers. Integers in even numbered positions
(0, 2, 4 etc) represent the start of a run of numbers while those in odd
numbered positions represent the ends of runs. As an example the set (1,
3-7, 9, 11, 12) would be represented internally as (1, 2, 3, 8, 11, 13).

=head2 Comparision with Set::IntSpan

The C<Set::IntSpan> module represents sets of integers as a number of
inclusive ranges, for example '1-10,19-23,45-48'. Because many of its
operations involve linear searches of the list of ranges its overall
performance tends to be proportional to the number of distinct ranges.
This is fine for small sets but suffers compared to other possible set
representations (bit vectors, hash keys) when the number of ranges
grows large.

This module also represents sets as ranges of values but stores those
ranges in order and uses a binary search for many internal operations
so that overall performance tends towards O log N where N is the number
of ranges.

=head1 INTERFACE

=cut

use constant POSITIVE_INFINITY => 2**31 - 2;
use constant NEGATIVE_INFINITY => -2**31 + 100;

=head2 C<new>

Create a new set. Any arguments will be processed by a call to
C<add_from_string>:

    my $set = Set::IntSpan::Fast->new( '1, 3, 5, 10-100' );

Because C<add_from_string> handles multiple arguments this will work:

    my @nums = ( 1, 2, 3, 4, 5 );
    my $set = Set::IntSpan::Fast->new( @nums );

Bear in mind though that this validates each element of the array is it
would if you called C<add_from_string> so for large sets it will be
slightly more efficient to create an empty set and then call C<add>.

=cut

sub new {
    my $class = shift;
    my $self = bless [], $class;
    $self->add_from_string( @_ ) if @_;
    return $self;
}

=head2 C<invert>

Complement the set. Because our notion of infinity is actually
disappointingly finite inverting a finite set results in another finite
set. For example inverting the empty set makes it contain all the
integers between C<NEGATIVE_INFINITY> and C<POSITIVE_INFINITY> inclusive.

As noted above C<NEGATIVE_INFINITY> and C<POSITIVE_INFINITY> are actually just
big integers.

=cut

sub invert {
    my $self = shift;

    if ( $self->is_empty() ) {

        # Empty set
        @$self = ( NEGATIVE_INFINITY, POSITIVE_INFINITY );
    }
    else {

        # Either add or remove infinity from each end. The net
        # effect is always an even number of additions and deletions
        if ( $self->[0] == NEGATIVE_INFINITY ) {
            shift @{$self};
        }
        else {
            unshift @{$self}, NEGATIVE_INFINITY;
        }

        if ( $self->[-1] == POSITIVE_INFINITY ) {
            pop @{$self};
        }
        else {
            push @{$self}, POSITIVE_INFINITY;
        }
    }
}

=head2 C<copy>

Return an identical copy of the set.

    my $new_set = $set->copy();

=cut

sub copy {
    my $self = shift;
    my $copy = Set::IntSpan::Fast->new();
    @$copy = @$self;
    return $copy;
}

=head2 C<add( $number ... )>

Add the specified integers to the set. Any number of arguments may be
specified in any order. All arguments must be integers between
C<Set::IntSpan::NEGATIVE_INFINITY> and C<Set::IntSpan::POSITIVE_INFINITY>
inclusive.

=cut

sub add {
    my $self = shift;
    $self->add_range( _list_to_ranges( @_ ) );
}

=head2 C<remove( $number ... )>

Remove the specified integers from the set. It is not an error to remove
non-members. Any number of arguments may be specified.

=cut

sub remove {
    my $self = shift;
    $self->remove_range( _list_to_ranges( @_ ) );
}

=head2 C<add_range( $from, $to )>

Add the inclusive range of integers to the set. Multiple ranges may be
specified:

    $set->add_range(1, 10, 20, 22, 15, 17);

Each pair of arguments constitute a range. The second argument in each
pair must be greater than or equal to the first.

=cut

sub add_range {
    my $self = shift;

    _iterate_ranges(
        @_,
        sub {
            my ( $from, $to ) = @_;

            my $fpos = $self->_find_pos( $from );
            my $tpos = $self->_find_pos( $to + 1, $fpos );

            $from = $self->[ --$fpos ] if ( $fpos & 1 );
            $to   = $self->[ $tpos++ ] if ( $tpos & 1 );

            splice @$self, $fpos, $tpos - $fpos, ( $from, $to );
        }
    );
}

=head2 C<add_from_string( $string )>

Add items to a set from a string representation, of the same form as
C<as_string>. Multiple strings may be supplied:

    $set->add_from_string( '1-10, 30-40', '100-200' );

is equivalent to

    $set->add_from_string( '1-10, 30-40, 100-200' );

By default items are separated by ',' and ranges delimited by '-'. You
may select different punctuation like this:

    $set->add_from_string( 
        { sep => ';', range => ':' },
        '1;3;5;7:11;19:27'
    );
    
When supplying an options hash in this way the C<sep> and C<range>
option may be either a regular expression or a literal string.

    $set->add_from_string( 
        { sep => qr/:+/, range => qr/[.]+/ },
        '1::3::5:7...11:19..27'
    );

And embedded whitespace in the string will be ignored.

=cut

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
            $match_range
              = qr/^ $match_number $ctl->{range} $match_number $/x;
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

=head2 C<remove_range( $from, $to )>

Remove the inclusive range of integers from the set. Multiple ranges may
be specified:

    $set->remove_range(1, 10, 20, 22, 15, 17);

Each pair of arguments constitute a range. The second argument in each
pair must be greater than or equal to the first.

=cut

sub remove_range {
    my $self = shift;

    $self->invert();
    $self->add_range( @_ );
    $self->invert();
}

=head2 C<remove_from_string( $string )>

Remove items to a set from a string representation, of the same form as
C<as_string>. As with C<add_from_string> the punctuation characters may
be specified.

=cut

sub remove_from_string {
    my $self = shift;

    $self->invert();
    $self->add_from_string( @_ );
    $self->invert();
}

=head2 C<merge( $set ... )>

Merge the members of the supplied sets into this set. Any number of sets
may be supplied as arguments.

=cut

sub merge {
    my $self = shift;

    for my $other ( @_ ) {
        my $iter = $other->iterate_runs();
        while ( my ( $from, $to ) = $iter->() ) {
            $self->add_range( $from, $to );
        }
    }
}

=head2 Operators

=head3 C<complement>

Returns a new set that is the complement of this set. See the comments
about our definition of infinity above.

=cut

sub compliment {
    croak
      "That's very kind of you - but I expect you meant complement()";
}

sub complement {
    my $new = shift->copy();
    $new->invert();
    return $new;
}

=head3 C<union( $set ... )>

Return a new set that is the union of this set and all of the supplied
sets. May be called either as a method:

    $un = $set->union( $other_set );
    
or as a function:

    $un = Set::IntSpan::Fast::union( $set1, $set2, $set3 );

=cut

sub union {
    my $new = Set::IntSpan::Fast->new();
    $new->merge( @_ );
    return $new;
}

=head3 C<intersection( $set )>

Return a new set that is the intersection of this set and all the supplied
sets. May be called either as a method:

    $in = $set->intersection( $other_set );
    
or as a function:

    $in = Set::IntSpan::Fast::intersection( $set1, $set2, $set3 );

=cut

sub intersection {
    my $new = Set::IntSpan::Fast->new();
    $new->merge( map { $_->complement() } @_ );
    $new->invert();
    return $new;
}

=head3 C<xor( $set )>

Return a new set that contains all of the members that are in this set
or the supplied set but not both. Can actually handle more than two sets
in which case it returns a set that contains all the members that are in
some of the sets but not all of the sets.

Can be called as a method or a function.

=cut

sub xor {
    return intersection( union( @_ ),
        intersection( @_ )->complement() );
}

=head3 C<diff( $set )>

Return a set containing all the elements that are in this set but not the
supplied set.

=cut

sub diff {
    my $first = shift;
    return intersection( $first, union( @_ )->complement() );
}

=head2 Tests

=head3 C<is_empty>

Return true if the set is empty.

=cut

sub is_empty {
    my $self = shift;

    return @$self == 0;
}

=head3 C<contains( $number )>

Return true if the specified number is contained in the set.

=cut

*contains = *contains_all;

=head3 C<contains_any($number, $number, $number ...)>

Return true if the set contains any of the specified numbers.

=cut

sub contains_any {
    my $self = shift;

    for my $i ( @_ ) {
        my $pos = $self->_find_pos( $i + 1 );
        return 1 if $pos & 1;
    }

    return;
}

=head3 C<contains_all($number, $number, $number ...)>

Return true if the set contains all of the specified numbers.

=cut

sub contains_all {
    my $self = shift;

    for my $i ( @_ ) {
        my $pos = $self->_find_pos( $i + 1 );
        return unless $pos & 1;
    }

    return 1;
}

=head3 C<contains_all_range( $low, $high )>

Return true if all the numbers in the range C<$low> to C<$high> (inclusive)
are in the set.

=cut

sub contains_all_range {
    my ( $self, $lo, $hi ) = @_;

    croak "Range limits must be in ascending order" if $lo > $hi;

    my $pos = $self->_find_pos( $lo + 1 );
    return ( $pos & 1 ) && $hi < $self->[$pos];
}

=head3 C<cardinality( [ $clip_lo, $clip_hi ] )>

Returns the number of members in the set. If a clipping range is supplied
return the count of members that fall within that inclusive range.

=cut

sub cardinality {
    my $self = shift;

    my $card = 0;
    my $iter = $self->iterate_runs( @_ );
    while ( my ( $from, $to ) = $iter->() ) {
        $card += $to - $from + 1;
    }

    return $card;
}

=head3 C<superset( $set )>

Returns true if this set is a superset of the supplied set. A set is
always a superset of itself, or in other words

    $set->superset( $set )
    
returns true.

=cut

sub superset {
    return subset( reverse( @_ ) );
}

=head3 C<subset( $set )>

Returns true if this set is a subset of the supplied set. A set is
always a subset of itself, or in other words

    $set->subset( $set )
    
returns true.

=cut

sub subset {
    my $self = shift;
    my $other = shift || croak "I need two sets to compare";
    return $self->equals( $self->intersection( $other ) );
}

=head3 C<equals( $set )>

Returns true if this set is identical to the supplied set.

=cut

sub equals {
    return unless @_;

    # Array of array refs
    my @edges = @_;
    my $medge = scalar( @edges ) - 1;

    POS: for ( my $pos = 0;; $pos++ ) {
        my $v = $edges[0]->[$pos];
        if ( defined( $v ) ) {
            for ( @edges[ 1 .. $medge ] ) {
                my $vv = $_->[$pos];
                return unless defined( $vv ) && $vv == $v;
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

=head2 Getting set contents

=cut

=head3 C<as_array>

Return an array containing all the members of the set in ascending order.

=cut

sub as_array {
    my $self = shift;
    my @ar   = ();
    my $iter = $self->iterate_runs();
    while ( my ( $from, $to ) = $iter->() ) {
        push @ar, ( $from .. $to );
    }

    return @ar;
}

=head3 C<as_string>

Return a string representation of the set.

    my $set = Set::IntSpan::Fast->new();
    $set->add(1, 3, 5, 7, 9);
    $set->add_range(100, 1_000_000);
    print $set->as_string(), "\n";    # prints 1,3,5,7,9,100-1000000

You may optionally supply a hash containing C<sep> and C<range> options:

    print $set->as_string({ sep => ';', range => '*' ), "\n";
        # prints 1;3;5;7;9;100*1000000

=cut

sub as_string {
    my $self = shift;
    my $ctl = { sep => ',', range => '-' };
    %$ctl = ( %$ctl, %{ $_[0] } ) if @_;
    my $iter = $self->iterate_runs();
    my @runs = ();
    while ( my ( $from, $to ) = $iter->() ) {
        push @runs,
          $from == $to ? $from : join( $ctl->{range}, $from, $to );
    }
    return join( $ctl->{sep}, @runs );
}

=head3 C<iterate_runs( [ $clip_lo, $clip_hi ] )>

Returns an iterator that returns each run of integers in the set in
ascending order. To iterate all the members of the set do something
like this:

    my $iter = $set->iterate_runs();
    while (my ( $from, $to ) = $iter->()) {
        for my $member ($from .. $to) {
            print "$member\n";
        }
    }

If a clipping range is specified only those members that fall within
the range will be returned.

=cut

sub iterate_runs {
    my $self = shift;

    if ( @_ ) {

        # Clipped iterator
        my ( $clip_lo, $clip_hi ) = @_;

        my $pos = $self->_find_pos( $clip_lo ) & ~1;
        my $limit = ( $self->_find_pos( $clip_hi + 1, $pos ) + 1 ) & ~1;

        return sub {
            TRY: {
                return if $pos >= $limit;

                my @r = ( $self->[$pos], $self->[ $pos + 1 ] - 1 );
                $pos += 2;

                # Catch some edge cases
                redo TRY if $r[1] < $clip_lo;
                return   if $r[0] > $clip_hi;

                # Clip to range
                $r[0] = $clip_lo if $r[0] < $clip_lo;
                $r[1] = $clip_hi if $r[1] > $clip_hi;

                return @r;
            }
        };
    }
    else {

        # Unclipped iterator
        my $pos   = 0;
        my $limit = scalar( @$self );

        return sub {
            return if $pos >= $limit;
            my @r = ( $self->[$pos], $self->[ $pos + 1 ] - 1 );
            $pos += 2;
            return @r;
        };
    }

}

sub _list_to_ranges {
    my @list   = sort { $a <=> $b } @_;
    my @ranges = ();
    my $count  = scalar( @list );
    my $pos    = 0;
    while ( $pos < $count ) {
        my $end = $pos + 1;
        $end++
          while $end < $count && $list[$end] <= $list[ $end - 1 ] + 1;
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

    my $high = scalar( @$self );

    while ( $low < $high ) {
        my $mid = int( ( $low + $high ) / 2 );
        if ( $val < $self->[$mid] ) {
            $high = $mid;
        }
        elsif ( $val > $self->[$mid] ) {
            $low = $mid + 1;
        }
        else {
            return $mid;
        }
    }

    return $low;
}

sub _iterate_ranges {
    my $cb = pop @_;

    my $count = scalar( @_ );

    croak "Range list must have an even number of elements"
      if ( $count % 2 ) != 0;

    for ( my $p = 0; $p < $count; $p += 2 ) {
        my ( $from, $to ) = ( $_[$p], $_[ $p + 1 ] );
        croak "Range limits must be integers"
          unless is_int( $from ) && is_int( $to );
        croak "Range limits must be in ascending order"
          unless $from <= $to;
        croak "Value out of range"
          unless $from >= NEGATIVE_INFINITY && $to <= POSITIVE_INFINITY;

        # Internally we store inclusive/exclusive ranges to
        # simplify comparisons, hence '$to + 1'
        $cb->( $from, $to + 1 );
    }
}

1;
__END__

=head2 Constants

The constants C<NEGATIVE_INFINITY> and C<POSITIVE_INFINITY> are exposed. As
noted above these are infinitely smaller than infinity but they're the
best we've got. They're not exported into the caller's namespace so if you
want to use them you'll have to use their fully qualified names:

    $set->add_range(1, Set::IntSpan::Fast::POSITIVE_INFINITY);

=head1 DIAGNOSTICS


=head3 C<< Range list must have an even number of elements >>

The lists of ranges passed to C<add_range> and C<remove_range> consist
of a number of pairs of integers each of which specify the start and end
of a range.

=head3 C<< Range limits must be integers >>

You may only add integers to sets.

=head3 C<< Range limits must be in ascending order >>

When specifying a range in a call to C<add_range> or C<remove_range> the
range bounds must be in ascending order. Multiple ranges don't need to
be in any particular order.

=head3 C<< Value out of range >>

Sets may only contain values in the range C<NEGATIVE_INFINITY> to
C<POSITIVE_INFINITY> inclusive.

=head3 C<< That's very kind of you - but I expect you meant complement() >>

The method that complements a set is called C<complement>.

=head3 C<< I need two sets to compare >>

C<superset> and C<subset> need two sets to compare. They may be called
either as a function:

    $ss = Set::IntSpan::Fast::subset( $s1, $s2 )
    
or as a method:

    $ss = $s1->subset( $s2 );

=head3 C<< Invalid Range String >>

The range string must only contain a comma separated list of ranges, with a hyphen used as the range limit separator. e.g. "1,5,8-12,15-29".


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in: A full explanation of any configuration
system(s) used by the module, including the names and locations of any
configuration files, and the meaning of any environment variables or
properties that can be set. These descriptions must also include details
of any configuration language used.

Set::IntSpan::Fast requires no configuration files or environment
variables.

=head1 DEPENDENCIES

    Data::Types
    List::Util

=head1 INCOMPATIBILITIES

Although this module was conceived as a replacement for C<Set::IntSpan>
it isn't a drop-in replacement.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to 
C<bug-set-intspan-fast@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

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
