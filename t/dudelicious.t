#!perl
use Test::More;    # tests => 3;

use strict;
use warnings;

use File::Temp qw/ tempdir /;
use File::Copy qw/ cp /;
use File::Spec;

BEGIN {
    eval "use Test::Mojo";
    plan skip_all => "Test::Mojo required for testing dudelicious" if $@;

}

my $todo_dir = tempdir( 'todo-XXXXXXXXX', CLEANUP => 1, TMPDIR => 1 );
$ENV{DUDELICIOUS_HOME} = $todo_dir;

foreach my $file qw( todo1.txt todo.list.txt dudelicious.conf ) {
    cp( File::Spec->catfile( 't',       $file ),
        File::Spec->catfile( $todo_dir, $file ),
    ) || die "Couldn't cp [$todo_dir]/[$file]: $!";
}

require File::Spec->catfile( 'bin', 'dudelicious.pl' );
Dudelicious->import;
Dudelicious->app->log->level('error');

my $t = Test::Mojo->new;

# Index page
$t->get_ok('/')->status_is(200)->content_like(qr/todo1\.txt/xms);

$t->get_ok('/l/todo1')->status_is(200)->content_is(
    q{<!doctype html><html>
    <head><title>Funky!</title></head>
    <body><h1>todo1</h1>
<ol>
    <li>
(B) +GarageSale @phone schedule Goodwill pickup
    </li>
    <li>
+GarageSale @home post signs around the neighborhood DUE:2006-08-01
    </li>
    <li>
X eat meatballs @home
    </li>
    <li>
(A) @phone thank Mom for the meatballs WAIT
    </li>
    <li>

    </li>
    <li>
@shopping Eskimo pies
    </li>
    <li>
email andrew@cpan.org for help +report_bug @wherever
    </li>
    <li>
x 2009-01-01 completed with a date
    </li>
</ol>
</body>
</html>
}
);

$t->get_ok('/l/todo1.txt')->status_is(200)->content_is(
    q{(B) +GarageSale @phone schedule Goodwill pickup
+GarageSale @home post signs around the neighborhood DUE:2006-08-01
X eat meatballs @home
(A) @phone thank Mom for the meatballs WAIT

@shopping Eskimo pies
email andrew@cpan.org for help +report_bug @wherever
x 2009-01-01 completed with a date
}
);

$t->get_ok('/l/todo1/e/1')->status_is(200)->content_is(
    q{<!doctype html><html>
    <head><title>Funky!</title></head>
    <body>(B) +GarageSale @phone schedule Goodwill pickup
</body>
</html>
}
);

$t->get_ok('/l/todo1/e/1.txt')->status_is(200)->content_is(
    q{(B) +GarageSale @phone schedule Goodwill pickup
}
);

done_testing();
