use Test::More tests => 2;

BEGIN {
  use_ok( 'Net::CIDR::Set' );
  use_ok( 'Net::CIDR::Set::PP' );
}

diag( "Testing Net::CIDR::Set $Net::CIDR::Set::VERSION" );
diag( "ISA @Net::CIDR::Set::ISA" );
