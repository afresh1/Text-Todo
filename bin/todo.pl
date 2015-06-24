#!/usr/bin/env perl
# $AFresh1: todo.pl,v 1.21 2010/02/03 18:14:01 andrew Exp $
########################################################################
# todo.pl *** a perl version of todo.sh. Uses Text::Todo:: modules.
#
# 2010.01.07 #*#*# andrew fresh <andrew@cpan.org>
########################################################################
# Copyright 2010 Andrew Fresh, all rights reserved
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
########################################################################
use strict;
use warnings;

use Text::Todo::Addon;
use Text::Todo::Config;
use Text::Todo::Help;
use Text::Todo::Client;

use version; our $VERSION = qv('0.1.2');

# option defaults
my $config_file = $ENV{HOME} . '/todo.cfg';
CONFIG: foreach my $f ( $config_file, $ENV{HOME} . '/.todo.cfg', ) {
    if ( -e $f ) {
        $config_file = $f;
        last CONFIG;
    }
}

my %aliases = (
    a     => 'add',
    app   => 'append',
    rm    => 'del',
    dp    => 'depri',
    ls    => 'list',
    lsa   => 'listall',
    lsc   => 'listcon',
    lf    => 'listfile',
    lsp   => 'listpri',
    lsprj => 'listproj',
    mv    => 'move',
    prep  => 'prepend',
    p     => 'pri',
);

my (%opts, %cl_opts_config);
Text::Todo::Config::get_options(\%opts, \%cl_opts_config);

if ( $opts{d} ) {
    $config_file = $opts{d};
}

Text::Todo::Help::usage( $opts{h} ) if $opts{h};

my $action = shift @ARGV;

Text::Todo::Help::usage( $opts{h} ) unless $action;

my $config = Text::Todo::Config::make_config(
    Text::Todo::Config::default_config(),
    Text::Todo::Config::read_config($config_file),
    Text::Todo::Config::env_config(),
    \%cl_opts_config
    );

if ( $action ne 'command' ) {
    my $addon = Text::Todo::Addon::for_name( $config, $action );
    if ( $addon ) {
	use Cwd 'abs_path';
	use File::Basename;
	$ENV{ uc $_ } = $config->{ $_ } for keys %$config;
	$ENV{TODO_FULL_SH} = abs_path($0);
	$ENV{TODO_SH} = basename($0);
	$ENV{TODOTXT_CFG_FILE} = $config_file;
	$addon->( $action, @ARGV );

	exit $?;
    }
}

if ( $action eq 'command' ) {
    $action = shift @ARGV;
}

if ( $action && exists $aliases{$action} ) {
    $action = $aliases{$action};
}

my @unsupported = grep { defined $opts{$_} } qw( v V );
if (@unsupported) {
    warn 'Unsupported options: ' . ( join q{, }, @unsupported ) . "\n";
}

if ( $action ) {
    my $client = Text::Todo::Client->new( config => $config );

    if ( $client->can( $action ) ) {
	$client->$action( @ARGV );
    }
}
else {
    Text::Todo::Help::usage();
}


__END__

=head1 NAME

todo.pl - a perl replacement for todo.sh


=head1 VERSION

Since the $VERSION can't be automatically included, 
here is the RCS Id instead, you'll have to look up $VERSION.

    $Id: todo.pl,v 1.22 2010/02/16 01:13:12 andrew Exp $


=head1 SYNOPSIS

    todo.pl list

    todo.pl -h

=head1 DESCRIPTION

Mostly compatible with todo.sh but not completely.
Any differences are either noted under limitations is a bug.

Ideally todo.pl should pass all the todo.sh tests.

This is a proof of concept to get the Text::Todo modules used. 

The modules are there to give more access to my todo.txt file from more
places.  My goal is a web API for a web interface and then a WebOS version for
my Palm Pre.

For more information see L<http://todotxt.com>

=head1 USAGE

See todo.pl -h

=head1 OPTIONS

See todo.pl -h

=head1 REQUIRED ARGUMENTS

See todo.pl -h

=head1 CONFIGURATION AND ENVIRONMENT

todo.pl should read the todo.cfg file that todo.sh uses.  It is a very
simplistic reader and would probably be easy to break.

It only uses TODO_DIR, TODO_FILE and DONE_DIR

It does not currently support any of the environment variables that todo.sh
uses.

=head1 DIAGNOSTICS

=head1 DEPENDENCIES 

Perl Modules:

=over

=item Text::Todo

=item version

=back


=head1 INCOMPATIBILITIES

Text::Todo::Entry actually checks if the entry is done before marking it
complete again.

Text::Todo::Entry will keep the completed marker and then the priority at the
beginning of the line in that order.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Known limitations:

Does not support some command line arguments. 
    f, h, v or V.

Does not yet support some actions.  Specifically, command, help and report. 

=head1 AUTHOR

Andrew Fresh  C<< <andrew@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Andrew Fresh C<< <andrew@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
