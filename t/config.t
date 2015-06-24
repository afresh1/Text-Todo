use strict;
use warnings;

use Test::More;
use Text::Todo::Config;

#
# check that default_config makes the right hash
#
is_deeply(Text::Todo::Config::default_config(),
	  {
	      NONE                          => '',
	      BLACK                         => "'\\\\033[0;30m'",
	      RED                           => "'\\\\033[0;31m'",
	      GREEN                         => "'\\\\033[0;32m'",
	      BROWN                         => "'\\\\033[0;33m'",
	      BLUE                          => "'\\\\033[0;34m'",
	      PURPLE                        => "'\\\\033[0;35m'",
	      CYAN                          => "'\\\\033[0;36m'",
	      LIGHT_GREY                    => "'\\\\033[0;37m'",
	      DARK_GREY                     => "'\\\\033[1;30m'",
	      LIGHT_RED                     => "'\\\\033[1;31m'",
	      LIGHT_GREEN                   => "'\\\\033[1;32m'",
	      YELLOW                        => "'\\\\033[1;33m'",
	      LIGHT_BLUE                    => "'\\\\033[1;34m'",
	      LIGHT_PURPLE                  => "'\\\\033[1;35m'",
	      LIGHT_CYAN                    => "'\\\\033[1;36m'",
	      WHITE                         => "'\\\\033[1;37m'",
	      DEFAULT                       => "'\\\\033[0m'",
# Default priority->color map.
	      PRI_A                         => "'\\\\033[1;33m'",
	      PRI_B                         => "'\\\\033[0;32m'",
	      PRI_C                         => "'\\\\033[1;34m'",
	      PRI_X                         => "'\\\\033[1;37m'",
# Default project and context colors.
	      COLOR_PROJECT                 => '',
	      COLOR_CONTEXT                 => '',
# Default highlight colors.
	      COLOR_DONE                    => "'\\\\033[0;37m'",
# Default options
              TODOTXT_FORCE                 => 0,
              TODOTXT_PRESERVE_LINE_NUMBERS => 1,
  	      TODOTXT_AUTO_ARCHIVE          => 1,
	      TODOTXT_PLAIN                 => 0,
	      TODOTXT_DATE_ON_ADD           => 0,
	      HIDE_PRIORITY                 => 0,
	      HIDE_CONTEXT                  => 0,
	      HIDE_PROJECT                  => 0,
	  },
	  'default_config - value expansion');

#
# check that the latter hash overrides the former
#
is_deeply(Text::Todo::Config::make_config(
	      {
		  K00 => 'v00',
		  K01 => 'v01',
	      },
	      {
		  K00 => 'value00',
		  K01 => 'value01',
	      }),
	  {
	      k00 => 'value00',
	      k01 => 'value01',
	  },
	  'make_config - hash overrides');

#
# check that values expand properly and keys are lowercased
#
is_deeply(Text::Todo::Config::make_config(
	      {
		  K00 => 'v00',
		  K01 => 'v01',
	      },
	      {
		  K10 => 'K00', # should become v00
		  K11 => 'v11',
	      }),
	  {
	      k00 => 'v00',
	      k01 => 'v01',
	      k10 => 'v00',
	      k11 => 'v11',
	  },
	  'make_config - value expansion, keys to lower case');


#
# check env variables capturing
#
{
    local %ENV = ( 'TODOTXT_PLAIN', 1 );
    is_deeply(Text::Todo::Config::make_config(
		  Text::Todo::Config::env_config()),
	      { lc 'TODOTXT_PLAIN' => 1 },
	      'env_config - env variable captured');
}
#
# check options detection
#
my (%opts, %opts_config);

sub setup {
    @ARGV = @_;
    %opts = ();
    %opts_config = ();
    Text::Todo::Config::get_options(\%opts, \%opts_config);
}

setup ();
is_deeply(\%opts_config,
	  {
	  },
	  'get_options - option defaults');

setup qw( -+ -+ -- -+ );
is( $opts_config{ HIDE_CONTEXT }, 0, 'get_options - processing stops at --' );

setup qw( -+ -+ - -+ );
is( $opts_config{ HIDE_CONTEXT }, 0, 'get_options - processing stops at -' );

setup qw( -apd list -P);
is( $opts_config{ HIDE_PRIORITY },
    1,
    'get_options - reads args following non-bundled paths' );

setup qw( -dP/todo.cfg list );
is( $opts_config{ HIDE_PRIORITY },
    undef,
    'get_options - chars from bundled paths are not considered options' );

setup qw( -aA -a -dP/todo.cfg list );
is( $opts_config{ TODOTXT_AUTO_ARCHIVE },
    0,
    'get_options - switching a and A options: -a is final' );

setup qw( -aA -dP/todo.cfg list );
is( $opts_config{ TODOTXT_AUTO_ARCHIVE },
    1,
    'get_options - switching a and A options: -A is final' );

setup qw( -a -t -f -c -n -dP/todo.cfg list );
is( $opts_config{ TODOTXT_AUTO_ARCHIVE },
    0,
    'get_options - detecting a option when followed by other options' );

setup qw( -A -t -f -c -n -dP/todo.cfg list );
is( $opts_config{ TODOTXT_AUTO_ARCHIVE },
    1,
    'get_options - detecting a option when followed by other options' );

setup qw( -cp -c -dP/todo.cfg list );
is( $opts_config{ TODOTXT_PLAIN },
    0,
    'get_options - switching c and p options: -c is final' );

setup qw( -cp -dP/todo.cfg list );
is( $opts_config{ TODOTXT_PLAIN },
    1,
    'get_options - switching c and p options: -p is final' );

setup qw( -c -t -f -a -n -dP/todo.cfg list );
is( $opts_config{ TODOTXT_PLAIN },
    0,
    'get_options - detecting c option when followed by other options' );

setup qw( -p -t -f -a -n -dP/todo.cfg list );
is( $opts_config{ TODOTXT_PLAIN },
    1,
    'get_options - detecting p option when followed by other options' );

setup qw( -tT -t -dP/todo.cfg list );
is( $opts_config{ TODOTXT_DATE_ON_ADD },
    1,
    'get_options - switching t and T options: -t is final' );

setup qw( -tT -dP/todo.cfg list );
is( $opts_config{ TODOTXT_DATE_ON_ADD },
    0,
    'get_options - switching t and T options: -T is final' );

setup qw( -t -c -f -a -n -dP/todo.cfg list );
is( $opts_config{ TODOTXT_DATE_ON_ADD },
    1,
    'get_options - detecting t option when followed by other options' );

setup qw( -T -c -f -a -n -dP/todo.cfg list );
is( $opts_config{ TODOTXT_DATE_ON_ADD },
    0,
    'get_options - detecting T option when followed by other options' );

setup qw( -nN -n -dP/todo.cfg list );
is( $opts_config{ TODOTXT_PRESERVE_LINE_NUMBERS },
    0,
    'get_options - switching n and N options: -n is final' );

setup qw( -nN -dP/todo.cfg list );
is( $opts_config{ TODOTXT_PRESERVE_LINE_NUMBERS },
    1,
    'get_options - switching n and N options: -N is final' );

setup qw( -n -t -dP/todo.cfg list );
is( $opts_config{ TODOTXT_PRESERVE_LINE_NUMBERS },
    0,
    'get_options - detecting n option when followed by other options' );

setup qw( -N -t -dP/todo.cfg list );
is( $opts_config{ TODOTXT_PRESERVE_LINE_NUMBERS },
    1,
    'get_options - detecting N option when followed by other options' );

setup qw( -f -dP/todo.cfg list );
is( $opts_config{ TODOTXT_FORCE },
    1,
    'get_options - detecting f option' );

setup qw( -f -n -dP/todo.cfg list );
is( $opts_config{ TODOTXT_FORCE },
    1,
    'get_options - detecting f option when followed by other options' );

setup qw( -dt/todo.cfg  --- -P ls );
is( $opts{ P }, 1, 'get_options - three dashes pass' );

setup qw( -P@@+++ -P -P  -PP );
is_deeply(\%opts_config,
	  {
	      HIDE_PRIORITY        => 1,
	      HIDE_CONTEXT         => 0,
	      HIDE_PROJECT         => 1,
	  },
	  'get_options - switching P, + and @ options');

done_testing();
