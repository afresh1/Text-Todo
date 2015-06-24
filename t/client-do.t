use strict;
use warnings;

use Test::More tests => 10;

use Text::Todo::Test;

test_todo_session 'do usage', <<'EOF';
>>> todo.sh do B B
usage: todo.pl do ITEM#[, ITEM#, ITEM#, ...]
=== 1
EOF
    ;
test_todo_session 'do missing ITEM#', <<'EOF';
>>> todo.sh do
usage: todo.pl do ITEM#[, ITEM#, ITEM#, ...]
=== 1
EOF
    ;
test_set_content data => <<'EOF';
smell the uppercase Roses +flowers @outside
notice the sunflowers
stop
remove1
remove2
remove3
remove4
EOF
    ;
my $todo_dir = Text::Todo::Test::get_config()->{TODO_DIR};
use Text::Todo::Entry;
Text::Todo::Entry->_set_time( sub { '2009-02-13' } );

test_todo_session 'basic do', <<EOF;
>>> todo.sh list
2 notice the sunflowers
4 remove1
5 remove2
6 remove3
7 remove4
1 smell the uppercase Roses +flowers \@outside
3 stop
--
TODO: 7 of 7 tasks shown

>>> todo.sh do 7,6
7 x 2009-02-13 remove4
TODO: 7 marked as done.
6 x 2009-02-13 remove3
TODO: 6 marked as done.
x 2009-02-13 remove3
x 2009-02-13 remove4
TODO: $todo_dir/todo.txt archived.

>>> todo.sh -p list
2 notice the sunflowers
4 remove1
5 remove2
1 smell the uppercase Roses +flowers \@outside
3 stop
--
TODO: 5 of 5 tasks shown

>>> todo.sh do 5 4
5 x 2009-02-13 remove2
TODO: 5 marked as done.
4 x 2009-02-13 remove1
TODO: 4 marked as done.
x 2009-02-13 remove1
x 2009-02-13 remove2
TODO: $todo_dir/todo.txt archived.

>>> todo.sh -p list
2 notice the sunflowers
1 smell the uppercase Roses +flowers \@outside
3 stop
--
TODO: 3 of 3 tasks shown
EOF
    ;
test_todo_session 'fail multiple do attempts', <<'EOF';
>>> todo.sh -a do 3
3 x 2009-02-13 stop
TODO: 3 marked as done.

>>> todo.sh -a do 3
TODO: 3 is already marked done.
EOF
    ;
test_todo_session 'fail non-existant item', <<'EOF';
>>> todo.sh -a do 42
TODO: No task 42
EOF
    ;
#done_testing();

