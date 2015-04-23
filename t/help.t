use strict;
use warnings;

use Test::More;
use Text::Todo::Help;

ok( ! Text::Todo::Help::action_help( 'doesnotexist' ),
    'action_help - nonexisting action' );

my $actual = Text::Todo::Help::action_help( 'shorthelp' );
my $expected =<<'SHORTHELP';
    shorthelp
      List the one-line usage of all built-in and add-on actions.
SHORTHELP

is( $$actual, $expected, 'action_help - existing action' );

done_testing();
