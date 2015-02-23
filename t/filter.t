use strict;
use warnings;

use Test::More;

use Text::Todo::Filter;

my $f;
my $dc = _expand(
    {
	NONE          => '',
	BLACK         => "'\\\\033[0;30m'",
	RED           => "'\\\\033[0;31m'",
	GREEN         => "'\\\\033[0;32m'",
	BROWN         => "'\\\\033[0;33m'",
	BLUE          => "'\\\\033[0;34m'",
	PURPLE        => "'\\\\033[0;35m'",
	CYAN          => "'\\\\033[0;36m'",
	LIGHT_GREY    => "'\\\\033[0;37m'",
	DARK_GREY     => "'\\\\033[1;30m'",
	LIGHT_RED     => "'\\\\033[1;31m'",
	LIGHT_GREEN   => "'\\\\033[1;32m'",
	YELLOW        => "'\\\\033[1;33m'",
	LIGHT_BLUE    => "'\\\\033[1;34m'",
	LIGHT_PURPLE  => "'\\\\033[1;35m'",
	LIGHT_CYAN    => "'\\\\033[1;36m'",
	WHITE         => "'\\\\033[1;37m'",
	DEFAULT       => "'\\\\033[0m'",
# Default priority->color map.
	PRI_A         => 'YELLOW',
	PRI_B         => 'GREEN',
	PRI_C         => 'LIGHT_BLUE',
	PRI_X         => 'WHITE',
# Default project and context colors.
	COLOR_PROJECT => 'NONE',
	COLOR_CONTEXT => 'NONE',
# Default highlight colors.
	COLOR_DONE    => 'LIGHT_GREY',
    }
    );

sub _expand {
    my $cf = shift;
    while ( my ($key, $value) = each %$cf ) {
	$cf->{ $key } = $cf->{ $value }
	if exists $cf->{ $value } && defined $cf->{ $value };
    }
    return $cf;
}

sub _merge_config {
    my ( $to, $from ) = @_;
    while ( my ( $key, $value ) = each %$from ) {
	$to->{ $key } = $from->{ $key } if $from->{ $key };
    }
    return $to;
}

sub setup {
    my $cf = {};
    _expand( _merge_config( $cf, _expand($_) ) ) for @_ ;
    my %config;
    while ( my ($k, $v) = each %$cf ) {
	$config{lc $k} = $v;
    }
    $f = Text::Todo::Filter::make_filter(\%config);
}

sub test_filter {
    my ( $source, $expected, $message ) = @_;
    my $i = 0;
    is( $f->($_), @$expected[$i++], $message ) for @$source;
}

#
# check the highlighting of prioritized tasks
#
setup( $dc );
my @source = (
    '1 (A) @con01 +prj01 -- Some project 01 task, pri A',
    '2 (B) @con02 +prj02 -- Some project 02 task, pri B',
    '3 (C) @con01 +prj01 -- Some project 01 task, pri C',
    '4 (D) @con02 +prj02 -- Some project 02 task, pri D',
    '5 (E) @con01 +prj01 -- Some project 01 task, pri E',
    '6 (Z) @con02 +prj02 -- Some project 02 task, pri Z',
    '7 @con01 +prj01 -- Some project 01 task, no priority',
    '8 @con02 +prj02 -- Some project 02 task, no priority',
    );
my @expected = (
    '[1;33m1 (A) @con01 +prj01 -- Some project 01 task, pri A[0m',
    '[0;32m2 (B) @con02 +prj02 -- Some project 02 task, pri B[0m',
    '[1;34m3 (C) @con01 +prj01 -- Some project 01 task, pri C[0m',
    '[1;37m4 (D) @con02 +prj02 -- Some project 02 task, pri D[0m',
    '[1;37m5 (E) @con01 +prj01 -- Some project 01 task, pri E[0m',
    '[1;37m6 (Z) @con02 +prj02 -- Some project 02 task, pri Z[0m',
    '7 @con01 +prj01 -- Some project 01 task, no priority',
    '8 @con02 +prj02 -- Some project 02 task, no priority',
    );
test_filter(\@source, \@expected, 'default highlighting');

#
# check changing the color definitions into something other than ANSI color
# escape sequences
#
setup( $dc,
{
    YELLOW     => '${color yellow}',
    GREEN      => '${color green}',
    LIGHT_BLUE => '${color LightBlue}',
    WHITE      => '${color white}',
    DEFAULT    => '${color}',
    PRI_A => 'YELLOW',
    PRI_B => 'GREEN',
    PRI_C => 'LIGHT_BLUE',
    PRI_X => 'WHITE',
}
    );
@expected = (
    '${color yellow}1 (A) @con01 +prj01 -- Some project 01 task, pri A${color}',
    '${color green}2 (B) @con02 +prj02 -- Some project 02 task, pri B${color}',
    '${color LightBlue}3 (C) @con01 +prj01 -- Some project 01 task, pri C${color}',
    '${color white}4 (D) @con02 +prj02 -- Some project 02 task, pri D${color}',
    '${color white}5 (E) @con01 +prj01 -- Some project 01 task, pri E${color}',
    '${color white}6 (Z) @con02 +prj02 -- Some project 02 task, pri Z${color}',
    '7 @con01 +prj01 -- Some project 01 task, no priority',
    '8 @con02 +prj02 -- Some project 02 task, no priority',
    );

test_filter(\@source, \@expected, 'customized highlighting');

#
# check defining highlightings for more priorities than the default A, B, C
#
setup( $dc,
{
    PRI_E => 'BROWN',
    PRI_Z => 'LIGHT_PURPLE',
},
    );

@expected = (
    '[1;33m1 (A) @con01 +prj01 -- Some project 01 task, pri A[0m',
    '[0;32m2 (B) @con02 +prj02 -- Some project 02 task, pri B[0m',
    '[1;34m3 (C) @con01 +prj01 -- Some project 01 task, pri C[0m',
    '[1;37m4 (D) @con02 +prj02 -- Some project 02 task, pri D[0m',
    '[0;33m5 (E) @con01 +prj01 -- Some project 01 task, pri E[0m',
    '[1;35m6 (Z) @con02 +prj02 -- Some project 02 task, pri Z[0m',
    '7 @con01 +prj01 -- Some project 01 task, no priority',
    '8 @con02 +prj02 -- Some project 02 task, no priority',
    );
test_filter(\@source, \@expected, 'additional highlighting pri E+Z');

#
# check changing the fallback highlighting for undefined priorities
#
setup( $dc,
{
    PRI_X => 'BROWN',
}
    );

@expected = (
    '[1;33m1 (A) @con01 +prj01 -- Some project 01 task, pri A[0m',
    '[0;32m2 (B) @con02 +prj02 -- Some project 02 task, pri B[0m',
    '[1;34m3 (C) @con01 +prj01 -- Some project 01 task, pri C[0m',
    '[0;33m4 (D) @con02 +prj02 -- Some project 02 task, pri D[0m',
    '[0;33m5 (E) @con01 +prj01 -- Some project 01 task, pri E[0m',
    '[0;33m6 (Z) @con02 +prj02 -- Some project 02 task, pri Z[0m',
    '7 @con01 +prj01 -- Some project 01 task, no priority',
    '8 @con02 +prj02 -- Some project 02 task, no priority',
    );
test_filter(\@source, \@expected, 'different highlighting for pri X');

#
# check highlighting of done (but not yet archived) tasks
#
setup( $dc );

@source = (
    '1 (A) smell the uppercase Roses +flowers @outside',
    '3 notice the sunflowers',
    '4 remove2',
    '5 stop',
    '2 x 2009-02-13 remove1',
    );
@expected = (
    '[1;33m1 (A) smell the uppercase Roses +flowers @outside[0m',
    '3 notice the sunflowers',
    '4 remove2',
    '5 stop',
    '[0;37m2 x 2009-02-13 remove1[0m',
    );
test_filter(\@source, \@expected, 'highlighting of done tasks');

@source = (
    '1 (A) smell the uppercase Roses +flowers @outside',
    '3 notice the sunflowers',
    '5 stop',
    '2 x 2009-02-13 remove1',
    '4 x 2009-02-13 remove2',
    );
@expected = (
    '[1;33m1 (A) smell the uppercase Roses +flowers @outside[0m',
    '3 notice the sunflowers',
    '5 stop',
    '[0;37m2 x 2009-02-13 remove1[0m',
    '[0;37m4 x 2009-02-13 remove2[0m',
    );
test_filter(\@source, \@expected, 'highlighting of done tasks');

#
# check highlighting with hidden contexts/projects
#
setup( $dc,
{
    HIDE_CONTEXT => 1,
    HIDE_PROJECT => 1,
}
    );
@source = (
    '1 (A) +project at the beginning, with priority',
    '2 (B) with priority, ending in a +project',
    '3 (C) @context at the beginning, with priority',
    '4 (Z) with priority, ending in a @context',
    );
@expected = (
    '[1;33m1 (A) at the beginning, with priority[0m',
    '[0;32m2 (B) with priority, ending in a[0m',
    '[1;34m3 (C) at the beginning, with priority[0m',
    '[1;37m4 (Z) with priority, ending in a[0m',
    );
test_filter(\@source, \@expected, 'highlighting with hidden contexts/projects');

#
# check that priorities are only matched at the start of the task
#
setup( $dc );
@source = (
    '1 (D) some prioritized task',
    '2 not prioritized',
    '3 should not be seen as PRIORITIZE(D) task',
    '4 02 (D) a number at the start should not fool the filter',
    );
@expected = (
    '[1;37m1 (D) some prioritized task[0m',
    '2 not prioritized',
    '3 should not be seen as PRIORITIZE(D) task',
    '4 02 (D) a number at the start should not fool the filter',
    );
test_filter(\@source, \@expected, 'highlighting priority position');

#
# config specifying COLOR_PROJECT and COLOR_CONTEXT
#
setup( $dc,
{
    COLOR_CONTEXT => "'\\\\033[1m'",
    COLOR_PROJECT => "'\\\\033[2m'",
}
    );
@source = (
    '1 (A) prioritized @con01 context',
    '2 (B) prioritized +prj02 project',
    '3 (C) prioritized context at EOL @con03',
    '4 (D) prioritized project at EOL +prj04',
    '5 +prj05 non-prioritized project at BOL',
    '6 @con06 non-prioritized context at BOL',
    '7 multiple @con_ @texts and +pro_ +jects',
    '8 non-contexts: seti@home @ @* @(foo)',
    '9 non-projects: lost+found + +! +(bar)',
    );
@expected = (
    '[1;33m1 (A) prioritized [1m@con01[0m[1;33m context[0m',
    '[0;32m2 (B) prioritized [2m+prj02[0m[0;32m project[0m',
    '[1;34m3 (C) prioritized context at EOL [1m@con03[0m[1;34m[0m',
    '[1;37m4 (D) prioritized project at EOL [2m+prj04[0m[1;37m[0m',
    '5 [2m+prj05[0m non-prioritized project at BOL',
    '6 [1m@con06[0m non-prioritized context at BOL',
    '7 multiple [1m@con_[0m [1m@texts[0m and [2m+pro_[0m [2m+jects[0m',
    '8 non-contexts: seti@home @ @* @(foo)',
    '9 non-projects: lost+found + +! +(bar)',
    );
test_filter(\@source, \@expected, 'highlighting for contexts and projects');

#
# turn highlighting off
#
setup( $dc,
{
    COLOR_CONTEXT => "'\\\\033[1m'",
    COLOR_PROJECT => "'\\\\033[2m'",
    TODOTXT_PLAIN => 1,
}
    );
@expected = (
    '1 (A) prioritized @con01 context',
    '2 (B) prioritized +prj02 project',
    '3 (C) prioritized context at EOL @con03',
    '4 (D) prioritized project at EOL +prj04',
    '5 +prj05 non-prioritized project at BOL',
    '6 @con06 non-prioritized context at BOL',
    '7 multiple @con_ @texts and +pro_ +jects',
    '8 non-contexts: seti@home @ @* @(foo)',
    '9 non-projects: lost+found + +! +(bar)',
    );
test_filter(\@source, \@expected, 'turn highlighting off');

#
# suppressing display of contexts
#
setup( $dc,
{
    COLOR_CONTEXT => "'\\\\033[1m'",
    COLOR_PROJECT => "'\\\\033[2m'",
    HIDE_CONTEXT => 1,
}
    );
# Note that expected result No 8 is different from its todo.sh counterpart.
# todo.sh does not define properly what constitutes a context or a project body.
# For coloring it uses an awk program that insists on bodies ending with an
# alphanumeric. For suppressing display there is a sed command that does not 
# have such restriction. I chose to do both coloring and suppressing as in 
# todo.sh's awk program i.e. bodies end with an alnum.
@expected = (
    '[1;33m1 (A) prioritized context[0m',
    '[0;32m2 (B) prioritized [2m+prj02[0m[0;32m project[0m',
    '[1;34m3 (C) prioritized context at EOL[0m',
    '[1;37m4 (D) prioritized project at EOL [2m+prj04[0m[1;37m[0m',
    '5 [2m+prj05[0m non-prioritized project at BOL',
    '6 non-prioritized context at BOL',
    '7 multiple and [2m+pro_[0m [2m+jects[0m',
    '8 non-contexts: seti@home @ @* @(foo)',
    '9 non-projects: lost+found + +! +(bar)',
    );
test_filter(\@source, \@expected, 'suppressing display of contexts');

#
# suppressing display of projects
#
setup( $dc,
{
    COLOR_CONTEXT => "'\\\\033[1m'",
    COLOR_PROJECT => "'\\\\033[2m'",
    HIDE_PROJECT => 1,
}
    );
@expected = (
    '[1;33m1 (A) prioritized [1m@con01[0m[1;33m context[0m',
    '[0;32m2 (B) prioritized project[0m',
    '[1;34m3 (C) prioritized context at EOL [1m@con03[0m[1;34m[0m',
    '[1;37m4 (D) prioritized project at EOL[0m',
    '5 non-prioritized project at BOL',
    '6 [1m@con06[0m non-prioritized context at BOL',
    '7 multiple [1m@con_[0m [1m@texts[0m and',
    '8 non-contexts: seti@home @ @* @(foo)',
    '9 non-projects: lost+found + +! +(bar)',
    );
test_filter(\@source, \@expected, 'suppressing display of projects');

#
# suppressing display of priorities
#
setup( $dc,
{
    COLOR_CONTEXT => "'\\\\033[1m'",
    COLOR_PROJECT => "'\\\\033[2m'",
    HIDE_PROJECT => 1,
    HIDE_PRIORITY => 1,
}
    );
@expected = (
    '[1;33m1 prioritized [1m@con01[0m[1;33m context[0m',
    '[0;32m2 prioritized project[0m',
    '[1;34m3 prioritized context at EOL [1m@con03[0m[1;34m[0m',
    '[1;37m4 prioritized project at EOL[0m',
    '5 non-prioritized project at BOL',
    '6 [1m@con06[0m non-prioritized context at BOL',
    '7 multiple [1m@con_[0m [1m@texts[0m and',
    '8 non-contexts: seti@home @ @* @(foo)',
    '9 non-projects: lost+found + +! +(bar)',
    );
test_filter(\@source, \@expected, 'suppressing display of priorities');

done_testing();
