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


foreach my $p (
    '/',
    '/l/todo1',
    '/l/todo1.html',
    '/l/todo1.txt',
    '/l/todo1.json',
    '/l/todo1/e/1',
    '/l/todo1/e/1.html',
    '/l/todo1/e/1.json',
    '/l/todo1/t',
    '/l/todo1/t.txt',
    '/l/todo1/t.json',
) {
    my ($volume, $directories, $file) = File::Spec->splitpath($p);
    $file ||= 'index.html';

    if ($file !~ /\.[^.]+$/xms) {
        $file .= '.html';
    }


    my $f = File::Spec->catfile( 't', 'dudelicious', $volume, $directories,
        $file);

    SKIP: {
        skip "$f does not exist", 3 if ! -e $f;
        diag( "Getting [$f] from [$p]" );
        $t->get_ok($p)->status_is(200)->content_is( slurp( $f ) );
    }
}

done_testing();


sub slurp {
    my ($file) = @_;

    local $/;
    open my $fh, '<', $file or die $file . ': ' . $!;
    my $content = <$fh>;
    close $fh;

    return $content;
}
