use strict;
use warnings;

use Test::More tests => 8;

use Text::Todo::Test;

# Tests paths by which we might automatically add
# a date to each item.

#
# Add and list
#

test_set_content file => 'garden.txt';

test_todo_session 'cmd line first day', <<'EOF';
>>> todo.sh -t addto garden.txt notice the daisies
1 2009-02-13 notice the daisies
GARDEN: 1 added.

>>> todo.sh listfile garden.txt
1 2009-02-13 notice the daisies
--
GARDEN: 1 of 1 tasks shown
EOF
    ;
test_tick();

test_todo_session 'cmd line second day', <<'EOF';
>>> todo.sh -t addto garden.txt smell the roses
2 2009-02-14 smell the roses
GARDEN: 2 added.

>>> todo.sh listfile garden.txt
1 2009-02-13 notice the daisies
2 2009-02-14 smell the roses
--
GARDEN: 2 of 2 tasks shown
EOF
    ;
test_tick();

test_todo_session 'cmd line third day', <<'EOF';
>>> todo.sh -t addto garden.txt mow the lawn
3 2009-02-15 mow the lawn
GARDEN: 3 added.

>>> todo.sh listfile garden.txt
1 2009-02-13 notice the daisies
2 2009-02-14 smell the roses
3 2009-02-15 mow the lawn
--
GARDEN: 3 of 3 tasks shown
EOF
    ;

Text::Todo::Test::add_to_conf( TODOTXT_DATE_ON_ADD => 1 );

test_tick( 3600 );

test_todo_session 'config file third day', <<'EOF';
>>> todo.sh addto garden.txt take out the trash
4 2009-02-15 take out the trash
GARDEN: 4 added.

>>> todo.sh listfile garden.txt
1 2009-02-13 notice the daisies
2 2009-02-14 smell the roses
3 2009-02-15 mow the lawn
4 2009-02-15 take out the trash
--
GARDEN: 4 of 4 tasks shown
EOF
    ;
#done_testing();

