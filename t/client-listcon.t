use strict;
use warnings;

use Test::More tests => 5;

use Text::Todo::Test;

test_set_content data => <<'EOF';
item 1
item 2
item 3
EOF
    ;
test_todo_session 'listcon no contexts', <<'EOF';
>>> todo.sh listcon
EOF
    ;
test_set_content data => <<'EOF';
(A) @1 -- Some context 1 task, whitespace, one char
(A) @c2 -- Some context 2 task, whitespace, two char
@con03 -- Some context 3 task, no whitespace
@con04 -- Some context 4 task, no whitespace
@con05@con06 -- weird context
EOF
    ;
test_todo_session 'Single context per line', <<'EOF';
>>> todo.sh listcon
@1
@c2
@con03
@con04
@con05@con06
EOF
    ;
test_set_content data => <<'EOF';
@con01 -- Some context 1 task
@con02 -- Some context 2 task
@con02 @con03 -- Multi-context task
EOF
    ;
test_todo_session 'Multi-context per line', <<'EOF';
>>> todo.sh listcon
@con01
@con02
@con03
EOF
    ;
test_set_content data => <<'EOF';
@con01 -- Some context 1 task
@con02 -- Some context 2 task
@con02 ginatrapani@gmail.com -- Some context 2 task
EOF
    ;
test_todo_session 'listcon e-mail address test', <<'EOF';
>>> todo.sh listcon
@con01
@con02
EOF
    ;
test_set_content data => <<'EOF';
(B) smell the uppercase Roses +roses @outside +shared
(C) notice the sunflowers +sunflowers @garden +shared +landscape
stop
EOF
    ;
test_todo_session 'listcon with project', <<'EOF';
>>> todo.sh listcon +landscape
@garden
EOF
    ;
#done_testing();

