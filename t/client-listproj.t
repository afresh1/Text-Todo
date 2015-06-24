use strict;
use warnings;

use Test::More tests => 6;

use Text::Todo::Test;

test_set_content data => <<'EOF';
item 1
item 2
item 3
EOF
    ;
test_todo_session 'listproj no projects', <<'EOF';
>>> todo.sh listcon
EOF
    ;
test_set_content data => <<'EOF';
(A) +1 -- Some project 1 task, whitespace, one char
(A) +p2 -- Some project 2 task, whitespace, two char
+prj03 -- Some project 3 task, no whitespace
+prj04 -- Some project 4 task, no whitespace
+prj05+prj06 -- weird project
EOF
    ;
test_todo_session 'Single project per line', <<'EOF';
>>> todo.sh listproj
+1
+p2
+prj03
+prj04
+prj05+prj06
EOF
    ;
test_set_content data => <<'EOF';
+prj01 -- Some project 1 task
+prj02 -- Some project 2 task
+prj02 +prj03 -- Multi-project task
EOF
    ;
test_todo_session 'Multi-project per line', <<'EOF';
>>> todo.sh listproj
+prj01
+prj02
+prj03
EOF
    ;
test_set_content data => <<'EOF';
+prj01 -- Some project 1 task
+prj02 -- Some project 2 task
+prj02 ginatrapani+todo@gmail.com -- Some project 2 task
EOF
    ;
test_todo_session 'listproj embedded + test', <<'EOF';
>>> todo.sh listproj
+prj01
+prj02
EOF
    ;
test_set_content data => <<'EOF';
(B) smell the uppercase Roses +roses @outside +shared
(C) notice the sunflowers +sunflowers @garden +shared +landscape
stop
EOF
    ;
test_todo_session 'basic listproj' => <<'EOF';
>>> todo.sh listproj
+landscape
+roses
+shared
+sunflowers
EOF
    ;
test_todo_session 'listproj with context', <<'EOF';
>>> todo.sh listproj @garden
+landscape
+shared
+sunflowers
EOF
    ;
#done_testing();

