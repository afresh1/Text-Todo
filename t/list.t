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
#     REVISION:  $RedRiver: list.t,v 1.5 2010/01/09 07:02:35 andrew Exp $
#===============================================================================

use strict;
use warnings;

use Test::More tests => 49;

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
ok( @pri_list = $copy->listpri, 'list priority item' );
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

ok( @projects = $copy->listproj, 'listproj for current list' );
is_deeply( \@projects, [ 'dos', 'uno' ], 'got the projects we expected' );

my $entry_to_archive;
ok( $entry_to_archive = $copy->list->[3], 'read entry_to_archive' );
is( $entry_to_archive->text,
    'x completed entry 4',
    'make sure we got the right entry'
);

ok( $copy->archive, 'archive done items' );
isnt( $copy->list->[1]->text,
    $entry_to_archive->text, 'make sure it changed' );

ok( $copy->load('done_file'), 'read the done_file' );
is( $copy->list->[-1]->text,
    $entry_to_archive->text, 'make sure it moved to the archive' );

my $file;
ok( $file = $copy->file('done_file'), 'get the done_file name' );
is( $file, $todo_dir . '/done.txt', 'the done_file name what we expected?' );

ok( $copy->addto( $file, 'added text' ), 'Add text to file' );

my @done;
ok( @done = $copy->listfile('done_file'), 'get items in done_file' );
is( $done[-1]->text, 'added text', 'make sure what we added is there' );

is( $done[-2]->text, $entry_to_archive->text,
    'make sure it moved to the archive' );

done_testing();
