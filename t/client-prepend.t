use strict;
use warnings;

use Test::More tests => 19;

use Text::Todo::Test;

test_todo_session( 'prepend usage', <<'EOF'
>>> todo.sh prepend B B
usage: todo.pl prepend ITEM# "TEXT TO PREPEND"
=== 1
EOF
    );

test_set_content data => <<'EOF'
(B) smell the uppercase Roses +flowers @outside
notice the sunflowers
stop
EOF
    ;

test_todo_session( 'basic prepend', <<'EOF'
>>> todo.sh list
[0;32m1 (B) smell the uppercase Roses +flowers @outside[0m
2 notice the sunflowers
3 stop
--
TODO: 3 of 3 tasks shown

>>> todo.sh -p list
1 (B) smell the uppercase Roses +flowers @outside
2 notice the sunflowers
3 stop
--
TODO: 3 of 3 tasks shown

>>> todo.sh prepend 2 test
2 test notice the sunflowers

>>> todo.sh -p list
1 (B) smell the uppercase Roses +flowers @outside
3 stop
2 test notice the sunflowers
--
TODO: 3 of 3 tasks shown

>>> todo.sh prepend 1 test
1 (B) test smell the uppercase Roses +flowers @outside

>>> todo.sh -p list
1 (B) test smell the uppercase Roses +flowers @outside
3 stop
2 test notice the sunflowers
--
TODO: 3 of 3 tasks shown

EOF
   );

test_todo_session 'prepend with &', <<'EOF'
>>> todo.sh prepend 3 "no running & jumping now"
3 no running & jumping now stop
EOF
   ;
test_set_content data => 'jump on hay';

test_todo_session( 'prepend with spaces', <<'EOF'
>>> todo.sh prepend 1 "notice the   three   spaces and"
1 notice the   three   spaces and jump on hay
EOF
   );
test_set_content data => <<'EOF'
smell the cows
grow some corn
thrash some hay
chase the chickens
EOF
    ;
test_todo_session 'prepend with symbols', <<'EOF'
>>> todo.sh prepend 1 "~@#$%^&*()-_=+[{]}|;:',<.>/?"
1 ~@#$%^&*()-_=+[{]}|;:',<.>/? smell the cows

>>> todo.sh prepend 2 '\`!\\"'
2 \`!\\" grow some corn

>>> todo.sh list
4 chase the chickens
3 thrash some hay
2 \`!\\" grow some corn
1 ~@#$%^&*()-_=+[{]}|;:',<.>/? smell the cows
--
TODO: 4 of 4 tasks shown
EOF
   ;
test_set_content();
test_todo_session( 'prepend handling prepended date on add', <<'EOF'
>>> todo.sh -t add "new task"
1 2009-02-13 new task
TODO: 1 added.

>>> todo.sh prepend 1 "this is just a"
1 2009-02-13 this is just a new task
EOF
   );

test_set_content();
test_todo_session('prepend handling priority and prepended date on add', <<'EOF'
>>> todo.sh -t add "new task"
1 2009-02-13 new task
TODO: 1 added.

>>> todo.sh pri 1 A
1 (A) 2009-02-13 new task
TODO: 1 prioritized (A).

>>> todo.sh prepend 1 "this is just a"
1 (A) 2009-02-13 this is just a new task
EOF
   );

test_set_content();
test_todo_session( 'prepend with prepended date keeps both', <<'EOF'
>>> todo.sh -t add "new task"
1 2009-02-13 new task
TODO: 1 added.

>>> todo.sh prepend 1 "2010-07-04 this is just a"
1 2009-02-13 2010-07-04 this is just a new task
EOF
   );

#done_testing();

