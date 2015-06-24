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

my $options = {
    TODOTXT_FORCE                 => 0,
    TODOTXT_PRESERVE_LINE_NUMBERS => 1,
    TODOTXT_AUTO_ARCHIVE          => 1,
    TODOTXT_PLAIN                 => 0,
    TODOTXT_DATE_ON_ADD           => 0,
    HIDE_PRIORITY                 => 0,
    HIDE_CONTEXT                  => 0,
    HIDE_PROJECT                  => 0,
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

    my ( $priority, $context, $project,
	 $auto_archive_opt, $txt_plain_opt, $date_on_add_opt,
	 $preserve_line_number_opt, $force_opt );

    # make sure three or more dashes pass as in todo.sh
    @ARGV = map { /^---+$/ ? () : $_ } @ARGV;

    my @args;
    for ( @ARGV ) {
	last if /^--?$/;
	push @args, ( $_ );
    }
    # strip bundled config file i.e. cases like -dpath_to_todo.cfg
    @args = map { s/^(-+[^d]*)d.+/$1/; /^-+$/ ? () : $_ } @args;

    my $previous = '';
    for ( @args ) {
	# the first non-option should not be preceded by a -d
	last if /^[^-]/ && $previous !~ /^-+[+cfhpPnNtTvV\@aA]*d$/;
	$priority += () = /P/g;
	$context += () = /@/g;
	$project += () = /\+/g;

	my $reversed = scalar reverse;
	
	$auto_archive_opt = $1 if $reversed =~ /(a|A)/;
	$txt_plain_opt = $1 if $reversed =~ /(c|p)/;
	$date_on_add_opt = $1 if $reversed =~ /(t|T)/;
	$preserve_line_number_opt = $1 if $reversed =~ /(n|N)/;
	$force_opt = $1 if /(f)/;
	    
	$previous = $_;
    }

    Getopt::Std::getopts( q{+d:cfhpPnNtTvV@aA}, $opts );
    $config->{ 'HIDE_PRIORITY' } = $priority % 2 if defined $priority;
    $config->{ 'HIDE_CONTEXT' } = $context % 2 if defined $context;
    $config->{ 'HIDE_PROJECT' } = $project % 2 if defined $project;

    if ( defined $auto_archive_opt ) {
	$config->{TODOTXT_AUTO_ARCHIVE} = $auto_archive_opt eq 'a' ? 0 : 1;
    }
    if ( defined $txt_plain_opt ) {
	$config->{TODOTXT_PLAIN} = $txt_plain_opt eq 'c' ? 0 : 1;
    }
    if ( defined $date_on_add_opt ) {
	$config->{TODOTXT_DATE_ON_ADD} = $date_on_add_opt eq 't' ? 1 : 0;
    }
    if ( defined $preserve_line_number_opt ) {
	$config->{TODOTXT_PRESERVE_LINE_NUMBERS} =
	    $preserve_line_number_opt eq 'n' ? 0 : 1;
    }
    if ( defined $force_opt ) {
	$config->{TODOTXT_FORCE} = $force_opt eq 'f' ? 1 : 0;
    }
}

sub default_config {
    my %cf;
    return $merge->( \%cf, $colors, $properties, $options );
}

sub env_config {
    my %config;
    for my $k ( keys %$options ) {
	$config{ $k } = $ENV{$k} if exists $ENV{$k} && defined $ENV{$k};
    }
    return \%config;
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

my $parse_line = sub {
    my ( $line, $config ) = @_;

    $line =~ s/\r?\n$//xms;
    $line =~ s/\s*\#.*$//xms;
    return if !$line;

    if ($line =~ s/^\s*export\s+//xms) {
        my ( $key, $value ) = $line =~ /^([^=]+)\s*=\s*"?(.*?)"?\s*$/xms;
        if ($key) {
            foreach my $k ( keys %{ $config } ) {
                $value =~ s/\$\Q$k\E/$config->{$k}/gxms;
                $value =~ s/\${\Q$k\E}/$config->{$k}/gxms;
            }
            foreach my $k ( keys %ENV ) {
                $value =~ s/\$\Q$k\E/$ENV{$k}/gxms;
                $value =~ s/\${\Q$k\E}/$ENV{$k}/gxms;
            }
            $value =~ s/\$\w+//gxms;
            $value =~ s/\${\w+}//gxms;

            $config->{$key} = $value;
        }
    }

    return 1;
};

sub read_config {
    my ($file) = @_;

    my %config;

    open my $fh, '<', $file or die "Unable to open [$file] : $!\n";
LINE: while (<$fh>) {
        $parse_line->( $_, \%config );
    }
    close $fh or die "Unable to close [$file]: $!\n";

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

Provides a default color scheme and options.

=head2 get_options

    get_options(\%opts, \%cl_opts_config);

A wrapper around Getopt::Std::getopts. Sets up %opts by a call to
getopts(\%opts). Checks a, A, p, P, t, T, @ and + options and fills 
%cl_opts_config accordingly.

=head2 make_config

    make_config($hash_ref ... )

Combines one or more hashrefs in a single one with lowercased keys. See the 
synopsis. Values matching keys in preceding hashes are replaced by those keys' 
corresponding values.

=head2 env_config

    env_config()

Puts together the values of env variables that match certain options. Must be 
used in making a config to handle the possibility of an addon calling back the 
client.

=head2 read_config

    read_config($file);

Reads a todo.cfg configuration file. Return a hashref of the env variables that
are exported by todo.sh. 
