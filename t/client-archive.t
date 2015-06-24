use strict;
use warnings;

use Test::More tests => 2;

use Text::Todo::Test;

test_set_content data => <<'EOF';
one
two
three
one
x done
four
EOF
    ;
my $todo_dir = Text::Todo::Test::get_config()->{TODO_DIR};

test_todo_session 'archive with duplicates', <<EOF;
>>> todo.sh archive
x done
TODO: $todo_dir/todo.txt archived.
EOF
    ;
test_todo_session 'list after archive', <<'EOF';
>>> todo.sh list
5 four
1 one
4 one
3 three
2 two
--
TODO: 5 of 5 tasks shown
EOF
    ;
#done_testing();

