use strict;
use warnings;

use Getopt::Std;

package Text::Todo::Config;

my $colors = {
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
};

my $properties = {
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
};

my $merge = sub {
    my $dest = shift;

    for my $src ( @_ ) {
	while ( my ( $k, $v ) = each %$src ) {
	    $dest->{ $k } = (exists $dest->{ $v } && defined $dest->{ $v })
		? $dest->{ $v } : $v;
	}
    }
    return $dest;
};

sub get_options {
    my ($opts, $config) = @_;

    my ( $priority, $context, $project ) = ( 0, 0, 0 );
    for ( @ARGV ) {
	last if /^--?$/;
	$priority += () = /P/g;
	$context += () = /@/g;
	$project += () = /\+/g;
    }
    Getopt::Std::getopts( q{+d:fhpPntvV@}, $opts );
    $config->{ 'TODOTXT_PLAIN' } = defined $opts->{ 'p' };
    $config->{ 'HIDE_PRIORITY' } = $priority % 2;
    $config->{ 'HIDE_CONTEXT' } = $context % 2;
    $config->{ 'HIDE_PROJECT' } = $project % 2;
}

sub default_config {
    my %cf;
    return $merge->( \%cf, $colors, $properties );
}

sub make_config {
    my %dest;

    $merge->( \%dest, @_ );
    my %config;
    while ( my ($k, $v) = each %dest ) {
	$config{lc $k} = $v;
    }
    return \%config;
}

1;
__END__

=encoding utf8

=head1 NAME

Text::Todo::Config - Command line options and program configuration utilities

=head1 SYNOPSIS

    use Text::Todo::Config;

    my $config = Text::Todo::Config::make_config( $hash_ref ... );

=head1 DESCRIPTION

Config.pm groups configuration related functions used by client and testing 
code.

=head1 FUNCTIONS

=head2 default_config

    $config = default_config();

Provides a default color scheme.

=head2 get_options

    get_options(\%opts, \%cl_opts_config);

A wrapper around Getopt::Std::getopts. Sets up %opts by a call to
getopts(\%opts). Checks p, P, @ and + options and fills %cl_opts_config 
accordingly.

=head2 make_config

    make_config($hash_ref ... )

Combines one or more hashrefs in a single one with lowercased keys. See the 
synopsis. Values matching keys in preceding hashes are replaced by those keys' 
corresponding values.
    
