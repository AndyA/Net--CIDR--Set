package MyBuilder;

BEGIN {
  require Module::Build;
  @ISA = qw( Module::Build );
}

sub ACTION_testauthor {
  my $self = shift;
  $self->test_files( 'xt/author' );
  $self->ACTION_test;
}

sub ACTION_critic {
  exec qw( perlcritic -1 -q -profile perlcriticrc lib/ ), glob 't/*.t';
}

sub ACTION_tags {
  exec(
    qw(
     ctags -f tags --recurse --totals
     --exclude=blib
     --exclude=.svn
     --exclude='*~'
     --languages=Perl
     t/ lib/
     )
  );
}

sub ACTION_tidy {
  my $self = shift;

  my @extra = qw( Build.PL );

  my %found_files = map { %$_ } $self->find_pm_files,
   $self->_find_file_by_type( 'pm', 't' ),
   $self->_find_file_by_type( 'pm', 'inc' ),
   $self->_find_file_by_type( 't',  't' );

  my @files = ( keys %found_files,
    map { $self->localize_file_path( $_ ) } @extra );

  for my $file ( @files ) {
    system 'perltidy', '-b', $file;
    unlink "$file.bak" if $? == 0;
  }
}

1;
