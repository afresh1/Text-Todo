use strict;
use warnings;

use Test::More;
use Fcntl qw( :mode );
use File::Path qw( make_path );
use File::Temp qw( tempdir );
use Text::Todo::Addon;

sub set_exec {
    my $file = shift;
    my @st = stat $file;
    my $mode = $st[2];
    my $perm = S_IMODE($mode);
    $perm |= 0111;
    chmod $perm, $file;
}

my $base = tempdir( 'todotxt-XXXXXXX', CLEANUP => 1 );

sub setup {
    my ( $location, $name, $ecode, $acode ) = @_;

    make_path( "$base/$location" ) unless -d "$base/$location";

    open( my $fh, '>', "$base/$location/$name" )
	or die "Can't open file for writing: $!\n";

    if ( $acode ) {
	print { $fh } $acode;
    } else {
	print { $fh } <<ADDON_CODE;
#!/usr/bin/env perl
exit $ecode;
ADDON_CODE
    }

    close $fh;
    set_exec( "$base/$location/$name" );
}

sub run {
    my ( $config, $name ) = @_;

    my $ad = $config->{ lc 'TODO_ACTIONS_DIR' };

    if ( $ad ) {
	# Absolute path should be given
	$config->{ lc 'TODO_ACTIONS_DIR' } = "$base/$ad";
    }

    # We do not depend on $ENV{HOME} in the case of a user provided dir
    local $ENV{HOME} = $ad ? undef : "$base";

    my $addon = Text::Todo::Addon::for_name( $config, $name );
    $addon->();
}

setup( '.todo.actions.d', 'myaddon', 42 );
run( {}, 'myaddon' );
is ( $? >> 8, 42, 'for_name - addon found in default .todo.actions.d' );

setup( '.todo/actions', 'myaddon', 43 );
run( {}, 'myaddon' );
is ( $? >> 8, 43, 'for_name - .todo/actions shadows .todo.actions.d' );

setup( 'user_provided', 'myaddon', 44 );
run( { lc 'TODO_ACTIONS_DIR' => 'user_provided' }, 'myaddon' );
is ( $? >> 8, 44, 'for_name - user provided dir shadows default dirs' );

setup( 'user_provided', 'myaddon2', 42 );
my %addons;
Text::Todo::Addon::get_all(
    { lc 'TODO_ACTIONS_DIR' => "$base/user_provided" },
    \%addons );
my @names = sort keys %addons;
is_deeply(
    \@names,
    [ 'myaddon', 'myaddon2' ] ,
    'get_all - provides all available addons' );

done_testing();
