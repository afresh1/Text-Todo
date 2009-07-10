#
#===============================================================================
#
#         FILE:  50.read_todo.t
#
#  DESCRIPTION:  Reads in a sample todo.txt and makes sure it got it correctly
#
#       AUTHOR:  Andrew Fresh (AAF), andrew@cpan.org
#      COMPANY:  Red River Communications
#      CREATED:  07/09/09 11:45:52
#     REVISION:  $RedRiver$
#===============================================================================

use strict;
use warnings;
use File::Spec;
use Test::More tests => 24;

my $todo_file = File::Spec->catfile( 't', 'todo1.txt' );
my @todos = (
    {   text     => '(B) +GarageSale @phone schedule Goodwill pickup',
        priority => 'B',
        contexts => ['phone'],
        projects => ['GarageSale'],
    },
    {   text =>
            '+GarageSale @home post signs around the neighborhood DUE:2006-08-01',
        priority => undef,
        contexts => ['home'],
        projects => ['GarageSale'],
    },
    {   text     => 'eat meatballs @home',
        priority => undef,
        contexts => ['home'],
        projects => [],
    },
    {   text     => '(A) @phone thank Mom for the meatballs WAIT',
        priority => 'A',
        contexts => ['phone'],
        projects => [],
    },
    {   text     => '@shopping Eskimo pies',
        priority => undef,
        contexts => ['shopping'],
        projects => [],
    },
);

BEGIN: { use_ok( 'Text::Todo', 'use Text::Todo' ) }

diag("Testing 50 read Text::Todo $Text::Todo::VERSION");

my $todo = new_ok('Text::Todo');

#ok( $todo->load(), 'Load no file');

ok( $todo->load($todo_file), "Load file [$todo_file]" );

my $list;
ok( $list = $todo->list, 'Get list' );

for my $id ( 0 .. $#todos ) {
    my $sample = $todos[$id];
    my $read   = $list->[$id];

    is( $read->text,     $sample->{text},     "check text [$id]" );
    is( $read->priority, $sample->{priority}, "check priority [$id]" );
    is_deeply(
        [ $read->contexts ],
        $sample->{contexts},
        "check contexts [$id]"
    );
    is_deeply(
        [ $read->projects ],
        $sample->{projects},
        "check projects [$id]"
    );
}
