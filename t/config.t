use strict;
use warnings;

use Test::More;
use Text::Todo::Config;

#
# check that default_config makes the right hash
#
is_deeply(Text::Todo::Config::default_config(),
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
	      PRI_A         => "'\\\\033[1;33m'",
	      PRI_B         => "'\\\\033[0;32m'",
	      PRI_C         => "'\\\\033[1;34m'",
	      PRI_X         => "'\\\\033[1;37m'",
# Default project and context colors.
	      COLOR_PROJECT => '',
	      COLOR_CONTEXT => '',
# Default highlight colors.
	      COLOR_DONE    => "'\\\\033[0;37m'",
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
# check options detection
#
my (%opts, %opts_config);
@ARGV = qw( -p );
Text::Todo::Config::get_options(\%opts, \%opts_config);
is_deeply(\%opts_config,
	  {
	      TODOTXT_PLAIN => 1,
	      HIDE_PRIORITY => 0,
	      HIDE_CONTEXT  => 0,
	      HIDE_PROJECT  => 0,
	  },
	  'get_options - -p option present');

@ARGV = ();
%opts = ();
%opts_config = ();
Text::Todo::Config::get_options(\%opts, \%opts_config);
is_deeply(\%opts_config,
	  {
	      TODOTXT_PLAIN => '',
	      HIDE_PRIORITY => 0,
	      HIDE_CONTEXT  => 0,
	      HIDE_PROJECT  => 0,
	  },
	  'get_options - -p option missing');

@ARGV = qw( -P@@+++ -P -P  -PP );
%opts = ();
%opts_config = ();
Text::Todo::Config::get_options(\%opts, \%opts_config);
is_deeply(\%opts_config,
	  {
	      TODOTXT_PLAIN => '',
	      HIDE_PRIORITY => 1,
	      HIDE_CONTEXT  => 0,
	      HIDE_PROJECT  => 1,
	  },
	  'get_options - switching P, + and @ options');

done_testing();
