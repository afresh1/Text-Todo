use strict;
use warnings;

use Test::More tests => 16;

use Text::Todo::Test;

test_set_content data => 'notice the daisies';

test_todo_session 'append usage', <<'EOF';
>>> todo.sh append adf asdfa
=== 1
usage: todo.pl append ITEM# "TEXT TO APPEND"
EOF
    ;
test_todo_session 'append error', <<'EOF';
>>> todo.sh append 10 "hej!"
=== 1
TODO: No task 10.
EOF
    ;
test_todo_session 'basic append', <<'EOF';
>>> todo.sh append 1 "smell the roses"
1 notice the daisies smell the roses

>>> todo.sh list
1 notice the daisies smell the roses
--
TODO: 1 of 1 tasks shown
EOF
    ;
test_todo_session 'basic append with &', <<'EOF';
>>> todo.sh append 1 "see the wasps & bees"
1 notice the daisies smell the roses see the wasps & bees

>>> todo.sh list
1 notice the daisies smell the roses see the wasps & bees
--
TODO: 1 of 1 tasks shown
EOF
    ;
test_set_content data => 'jump on hay';
test_todo_session 'append with spaces', <<'EOF';
>>> todo.sh append 1 "and notice the   three   spaces"
1 jump on hay and notice the   three   spaces
EOF
    ;
test_set_content data => <<'EOF';
smell the cows
grow some corn
thrash some hay
chase the chickens
EOF
    ;
test_todo_session 'append with symbols', <<'EOF'
>>> todo.sh append 1 "~@#$%^&*()-_=+[{]}|;:',<.>/?"
1 smell the cows ~@#$%^&*()-_=+[{]}|;:',<.>/?

>>> todo.sh append 2 '\`!\\"'
2 grow some corn \`!\\"

>>> todo.sh list
4 chase the chickens
2 grow some corn \`!\\"
1 smell the cows ~@#$%^&*()-_=+[{]}|;:',<.>/?
3 thrash some hay
--
TODO: 4 of 4 tasks shown
EOF
    ;
test_set_content data => 'notice the daisies';
test_todo_session 'append of current sentence', <<'EOF';
>>> todo.sh append 1 ", lilies and roses"
1 notice the daisies, lilies and roses

>>> todo.sh append 1 "; see the wasps"
1 notice the daisies, lilies and roses; see the wasps

>>> todo.sh append 1 "& bees"
1 notice the daisies, lilies and roses; see the wasps & bees
EOF
    ;
$ENV{SENTENCE_DELIMITERS}='*,.:;&';
test_todo_session 'append of current sentence SENTENCE_DELIMITERS', <<'EOF';
>>> todo.sh -d special-delimiters.cfg append 1 "&beans"
1 notice the daisies, lilies and roses; see the wasps & bees&beans

>>> todo.sh -d special-delimiters.cfg append 1 "%foo"
1 notice the daisies, lilies and roses; see the wasps & bees&beans %foo

>>> todo.sh -d special-delimiters.cfg append 1 "*2"
1 notice the daisies, lilies and roses; see the wasps & bees&beans %foo*2
EOF
    ;
#done_testing();

