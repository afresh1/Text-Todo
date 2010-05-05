#!perl
# $AFresh1: dudelicious.t,v 1.8 2010/05/01 22:38:24 andrew Exp $
use Test::More;    # tests => 3;

use strict;
use warnings;

use File::Temp qw/ tempdir /;
use File::Copy qw/ cp /;
use File::Spec;

my $have_test_json = 1;

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

my @exts = ( q{}, '.html', '.txt', '.json' );

foreach my $p (
    '/',
    ( map { '/l/todo1' . $_ } @exts ),
    ( map { '/l/todo1/e/1' . $_ } @exts ),
    ( map { '/l/todo1/e/4' . $_ } @exts ),
    ( map { '/l/todo1/t' . $_ } @exts ),
    ( map { '/l/todo1/t/project' . $_ } @exts ),
    ( map { '/l/todo1/t/context' . $_ } @exts ),
    )
{
    my ( $volume, $directories, $file ) = File::Spec->splitpath($p);

    $file ||= 'index.html';
    $file .= '.html' if $file !~ /\.[^.]+$/xms;

    my $f = File::Spec->catfile( 't', 'dudelicious', $volume, $directories,
        $file );

SKIP: {
        skip "$f does not exist", 3 if !-e $f;

        open my $fh, '<', $f or die $f . ': ' . $!;
        my $content = do { local $/; <$fh> };
        close $fh;

        $t->get_ok( $p, {}, undef, "Get [$f] from [$p]" )
            ->status_is(200, 'With 200 status');

        if ( $f =~ /\.json$/xms ) {
            $t->json_content_is( Mojo::JSON->decode($content),
                'Check JSON content' );
        }
        else {
            $t->content_like( qr/\Q$content\E/xms, 'Check content' );
        }
    }
}

done_testing();
