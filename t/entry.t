#===============================================================================
#
#         FILE:  20.entry.t
#
#  DESCRIPTION:  Test an entry that we create
#
#       AUTHOR:  Andrew Fresh (AAF), andrew@cpan.org
#      COMPANY:  Red River Communications
#      CREATED:  07/10/09 11:32:39
#     REVISION:  $RedRiver: 20.entry.t,v 1.1 2009/07/10 22:26:14 andrew Exp $
#===============================================================================

use strict;
use warnings;

use Test::More tests => 29;    # last test to print

my $class = 'Text::Todo::Entry';

BEGIN: { use_ok( $class, "use $class" ) }

diag("Testing 20 entry $class $Text::Todo::Entry::VERSION");

my $e = new_ok($class);

is( $e->text,     '',    "Make sure entry is blank" );
is( $e->priority, undef, "check priority is undef" );
is_deeply( [ $e->contexts ], [], "check contexts are empty" );
is_deeply( [ $e->projects ], [], "check projects are empty" );

my %sample = (
    text => '(B) @home @work keep your shoulder to the grindstone +busywork',
    priority    => 'B',
    contexts    => [ 'home', 'work' ],
    projects    => ['busywork'],
    prepend     => 'before',
    append      => 'or something',
    new_project => 'notnapping',
    new_context => 'car',
);

ok( $e->change( $sample{text} ), 'Update entry' );
is( $e->text,     $sample{text},     "Make sure entry matches" );
is( $e->priority, $sample{priority}, "check priority" );
is_deeply( [ $e->contexts ], $sample{contexts}, "check contexts" );
is_deeply( [ $e->projects ], $sample{projects}, "check projects" );

$sample{text} =~ s/^( \s* \( $sample{priority} \))/$1 $sample{prepend}/xms;
ok( $e->prepend( $sample{prepend} ), 'Prepend entry' );
is( $e->text,     $sample{text},     "Make sure entry matches" );
is( $e->priority, $sample{priority}, "check priority" );
is_deeply( [ $e->contexts ], $sample{contexts}, "check contexts" );
is_deeply( [ $e->projects ], $sample{projects}, "check projects" );

$sample{text} .= ' ' . $sample{append};
ok( $e->append( $sample{append} ), 'Append entry' );
is( $e->text,     $sample{text},     "Make sure entry matches" );
is( $e->priority, $sample{priority}, "check priority" );
is_deeply( [ $e->contexts ], $sample{contexts}, "check contexts" );
is_deeply( [ $e->projects ], $sample{projects}, "check projects" );

ok( !$e->in_project( $sample{new_project} ), 'not in new project yet' );
push @{ $sample{projects} }, $sample{new_project};
$sample{text} .= ' +' . $sample{new_project};
ok( $e->append( '+' . $sample{new_project} ), 'Add project' );
is( $e->text, $sample{text}, "Make sure entry matches" );
ok( $e->in_project( $sample{new_project} ), 'now in new project' );

ok( !$e->in_context( $sample{new_context} ), 'not in new context yet' );
push @{ $sample{contexts} }, $sample{new_context};
$sample{text} .= ' @' . $sample{new_context};
ok( $e->append( '@' . $sample{new_context} ), 'Add context' );
is( $e->text, $sample{text}, "Make sure entry matches" );
ok( $e->in_context( $sample{new_context} ), 'now in new context' );
