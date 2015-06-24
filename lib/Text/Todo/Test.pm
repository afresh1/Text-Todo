use strict;
use warnings;

use Text::Todo::Client;

package Text::Todo::Test;
use Exporter 'import';
use Test::More;

our @EXPORT_OK = qw/ init get_config /;
our @EXPORT = qw/ test_set_content test_tick test_todo_session /;

use File::Temp qw/ tempdir /;
use Time::Piece;
use Time::Seconds;
use Try::Tiny;
use Carp;

use Text::Todo::Config;
 
my $todo_dir = tempdir( 'todo-XXXXXXXXX', CLEANUP => 1, TMPDIR => 1 );

my $todo_cfg = {
    TODO_DIR  => $todo_dir,
    TODO_FILE => "$todo_dir/todo.txt",
    DONE_FILE => "$todo_dir/done.txt",
};

my $client;
my $output;

my $date = Time::Piece->strptime("2009-02-13", "%Y-%m-%d");

init();

sub get_config {
    return $todo_cfg;
}

sub add_to_conf {
    my ( $k, $v ) = @_;
    $todo_cfg->{$k} = $v;
}

sub get_todo_file {
    return $todo_cfg->{TODO_FILE};
}

sub get_done_file {
    return $todo_cfg->{DONE_FILE};
}

sub test_tick {
    my ( $seconds ) = @_;
    $seconds //= 24 * 60 * 60;
    $date += $seconds ;
}

sub test_set_content {
    my %parameters = @_;
    $parameters{file} //= get_todo_file();
    $parameters{data} //= '';
    $parameters{mode} //= '>'; # override file by default

    use File::Basename;
    my ($filename, $dirs, $suffix) = fileparse($parameters{file});
    $parameters{file} = "$todo_dir/$filename" unless $dirs eq $todo_dir;

    open( my $fh, $parameters{mode}, "$parameters{file}" )
	or croak "Cannot open file: $!\n";
    print { $fh } $parameters{data};

    close $fh;
}

sub init {
    my %parameters = @_;
    $parameters{log}    //= sub { $output .= $_ for @_ };
    $parameters{date}   //= sub { $date->ymd };

    my $config = Text::Todo::Config::make_config(
	Text::Todo::Config::default_config(),
	$todo_cfg,
	$parameters{cl_config} );

    $client = Text::Todo::Client->new(
	config => $config,
	log    => $parameters{log},
	date   => $parameters{date}
	);
    $output = '';
}

sub test_todo_session {
    my ( $name, $session ) = @_;

    use Text::ParseWords;
    my @tests = split /(?<=\n)\n/, $session;
    my $test_no = 1;

    for my $t ( @tests ) {
	my @lines = split( "\n", $t, 2 );
	my $line = shift( @lines );
	$line =~ s/^\s+|\s+$//g; # trim line
	local @ARGV = parse_line( '\s+', 0, $line );
	shift @ARGV; # discard >>>
	shift @ARGV; # discard todo.sh

	use Text::Todo::Config;
	my ( %opts, %cl_config );
	%opts = ();
	%cl_config = ();
	Text::Todo::Config::get_options( \%opts, \%cl_config );

	init( cl_config => \%cl_config );

	my $action = shift @ARGV;
	$output = '';
	my $expected = $lines[0];

	try {
	    $client->$action( @ARGV );
	    is( $output, $expected, "$name $test_no" );
	} catch {
	    # Get rid of the exception indicator
	    $expected =~ s/^=== \d+\n//m;
	    is( $_, $expected, "$name $test_no" );
	};
	$test_no++;
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Text::Todo::Test - test functions

=head1 SYNOPSIS

    use Text::Todo::Test;

    test_set_content data => <<'EOF';
    (B) smell the uppercase Roses +flowers @outside
    (A) notice the sunflowers
    stop
    EOF
        ;
    test_todo_session 'basic list', <<'EOF';
    >>> todo.sh -p list
    2 (A) notice the sunflowers
    1 (B) smell the uppercase Roses +flowers @outside
    3 stop
    --
    TODO: 3 of 3 tasks shown
    EOF

=head1 DESCRIPTION

Test.pm provides testing functions similar to the test lib of todo.sh
The intent is to use todo.sh's tests with as little tweaking as possible.

=head1 FUNCTIONS

=head2 test_set_content

    test_set_content data => <<'EOF';
    (B) smell the uppercase Roses +flowers @outside
    (A) notice the sunflowers
    stop
    EOF
        ;

Used to set the content of todo.txt in the test directory.
It's named parameters are as follows:
    data - a string to use as a content. default empty string
    file - a file to use . default todo.txt
    mode - append(>>) or override(>) mode. default is override

=head2 test_tick

    test_tick( $seconds )
    test_tick()

Bump the clock with $seconds seconds or 24*60*60 seconds (default).

=head2 test_todo_session

    test_todo_session( $name, $session );

Runs a test session with a given name. Session is a multiline string.
See the synopsis and use cases in the various client-*.t files.

=head2 init

    init( cl_config => $hash_ref );

Constructs a Client object to be tested.
Named parameters used in Client construction are:
    cl_config - configuration hash that varies with each test case
    log       - a suitable output handlig fuction. (a default is provided)
    date      - a date function. (a default is provided)


    
