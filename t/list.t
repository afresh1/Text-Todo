#===============================================================================
#
#         FILE:  list.t
#
#  DESCRIPTION:  Test list commands
#
#
#       AUTHOR:  Andrew Fresh (AAF), andrew@cpan.org
#      COMPANY:  Red River Communications
#      CREATED:  01/07/10 19:11
#     REVISION:  $RedRiver: list.t,v 1.1 2010/01/08 04:38:44 andrew Exp $
#===============================================================================

use strict;
use warnings;

use Test::More;    #tests => 2;

use File::Temp qw/ tempdir /;
use Data::Dumper;

my $class = 'Text::Todo';

BEGIN: { use_ok( $class, "use $class" ) }

diag("Testing entry $class $Text::Todo::VERSION");

my $orig = new_ok( $class, ['t/todo.list.txt'] );
my @orig_list;
ok( @orig_list = $orig->list, 'get orig list' );

is( $orig->file('todo_file'), 't/todo.list.txt', 'orig todo_file matches' );
is( $orig->file('done_file'), 't/done.list.txt', 'orig done_file matches' );
is( $orig->file('report_file'),
    't/report.list.txt', 'orig report_file matches' );

my $todo_dir = tempdir( 'todo-XXXXXXXXX', CLEANUP => 1, TMPDIR => 1 );
my $copy = new_ok($class);

foreach my $e (@orig_list) {
    ok( $copy->add($e), 'add entry from orginal list' );
}
ok( $copy->save( $todo_dir . '/todo.txt' ), 'save the copy' );

is( $copy->file('todo_file'),
    $todo_dir . '/todo.txt',
    'copy todo_file matches'
);
is( $copy->file('done_file'),
    $todo_dir . '/done.txt',
    'copy done_file matches'
);
is( $copy->file('report_file'),
    $todo_dir . '/report.txt',
    'copy report_file matches'
);
my @copy_list;
ok( @copy_list = $copy->list, 'get copy list' );

for my $id ( 0 .. $#orig_list ) {
    is( $copy_list[$id]->text, $orig_list[$id]->text, "Entry $id matches" );
}

$orig = undef;

my @pri_list;
ok( @pri_list = $copy->listpri, 'load priority item' );
is( scalar @pri_list, 1, 'only 1 item in the priority list' );
is( $pri_list[0]->text, '(A) entry 1 @one +uno', 'priority item is correct' );

my $entry_to_move = $copy_list[-1];
ok( $copy->move( $entry_to_move, 1 ), 'move entry to position 1' );
ok( @copy_list = $copy->list, 'update our list' );
is( $copy_list[1]->text, $entry_to_move->text,
    'entry is in the new position' );

$entry_to_move = $copy_list[3];
ok( $copy->move( 3, 1 ), 'move entry 3 to position 1' );
ok( @copy_list = $copy->list, 'update our list' );
is( $copy_list[1]->text, $entry_to_move->text,
    'entry is in the new position' );

my @projects;
ok( @projects = $copy->listproj, 'listproj for current list' );
is_deeply(
    \@projects,
    [ 'delete', 'dos', 'uno' ],
    'got the projects we expected'
);

for my $id ( 0 .. $#copy_list ) {
    my $e = $copy_list[$id];
    if ( $e->in_project('delete') ) {
        ok( $copy->del($e), "deleting entry $id" );
        isnt( $copy->list->[$id]->text, $e->text, 'Entry seems to be gone' );
    }
}

@projects;
ok( @projects = $copy->listproj, 'listproj for current list' );
is_deeply( \@projects, [ 'dos', 'uno' ], 'got the projects we expected' );

TODO: {
    local $TODO = 'No tests for archive and it isn\'t even written yet';
    ok( $copy->archive );
}

TODO: {
    local $TODO = 'No tests for addto and it isn\'t even written yet';
    ok( $copy->addto );
}

TODO: {
    local $TODO = 'No tests for listfile and it isn\'t even written yet';
    ok( $copy->listfile );
}

done_testing();
