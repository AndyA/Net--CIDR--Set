#!/usr/bin/perl -w

require 5.008001;

use strict;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';

eval 'use Net::CIDR::Set::XS';

warn "================================================\n"
 . "For even faster set handling consider installing\n"
 . "Net::CIDR::Set::XS\n"
 . "================================================\n"
 if $@;

WriteMakefile(
  ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
  NAME          => 'Net::CIDR::Set',
  AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
  VERSION_FROM  => 'lib/Net/CIDR/Set.pm',
  ABSTRACT_FROM => 'lib/Net/CIDR/Set.pm',
  LICENSE       => 'perl',
  PL_FILES      => {},
  PREREQ_PM     => {
    'Test::More'  => 0,
    'Data::Types' => 0,
    'List::Util'  => 0,
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'Net-CIDR-Set-*' },
);
