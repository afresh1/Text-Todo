#!/usr/bin/perl
# $RedRiver: todo.pl,v 1.1 2010/01/09 05:25:44 andrew Exp $
########################################################################
# todo.pl *** a perl version of todo.sh. Uses Text::Todo.
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

use Data::Dumper;

use Getopt::Std;
use Text::Todo;

use version; our $VERSION = qv('0.0.1');

# option defaults
my $config_file = $ENV{HOME} . '/todo.cfg';

my %actions = (
    add      => \&unsupported,
    addto    => \&unsupported,
    append   => \&unsupported,
    archive  => \&unsupported,
    command  => \&unsupported,
    del      => \&unsupported,
    depri    => \&unsupported,
    do       => \&unsupported,
    help     => \&unsupported,
    list     => \&list,
    listall  => \&unsupported,
    listcon  => \&unsupported,
    listfile => \&unsupported,
    listpri  => \&unsupported,
    listproj => \&unsupported,
    move     => \&unsupported,
    prepend  => \&unsupported,
    pri      => \&unsupported,
    replace  => \&unsupported,
    report   => \&unsupported,
);

my %aliases = (
    a     => 'add',
    app   => 'append',
    rm    => 'del',
    dp    => 'depri',
    ls    => 'list',
    lsa   => 'listall',
    lsc   => 'listcon',
    lf    => 'listfile',
    lsp   => 'listri',
    lsprj => 'listproj',
    mv    => 'move',
    prep  => 'prepend',
    p     => 'pri',
);

my %opts;
getopts( '@+d:fhpPntvV', \%opts );

my $action = shift @ARGV;
if ( $action && $action eq 'command' ) {

    # We don't support action scripts so . . .
    $action = shift @ARGV;
}
if ( $action && exists $aliases{$action} ) {
    $action = $aliases{$action};
}

if ( $opts{h} || !$action ) {
    usage( $opts{h} );
}

my @unsupported = grep { defined $opts{$_} } qw( @ + f h p P n t v V );
if (@unsupported) {
    die 'Unsupported options: ' . ( join q{, }, @unsupported ) . "\n";
}

if ( $opts{d} ) {
    $config_file = $opts{d};
}

if ( exists $actions{$action} ) {
    my $config = read_config($config_file);
    my $action = $actions{$action}->( $config, @ARGV );
}
else {
    usage();
}

sub list {
    my ($config) = @_;
    my $todo = Text::Todo->new($config);
    $todo->load( $config->{todo_file} ) || die "Couldn't load todo_file\n";

    foreach my $entry ( sort { lc $a->text cmp lc $b->text } $todo->list ) {
        print $entry->text, "\n" or warn "Couldn't print: \n";
    }
}

sub unsupported { die "Unsupported action\n" }

sub usage {
    my ($long) = @_;

    print <<'EOL';
  * command list taken from todo.sh for compatibility
  Usage: todo.pl [-fhpantvV] [-d todo_config] action

EOL

    if ($long) {
        print <<'EOL';
  Actions:
    add|a "THING I NEED TO DO +project @context"
    addto DEST "TEXT TO ADD"
    append|app NUMBER "TEXT TO APPEND"
    archive
    command [ACTIONS]
    del|rm NUMBER [TERM]
    dp|depri NUMBER
    do NUMBER
    help
    list|ls [TERM...]
    listall|lsa [TERM...]
    listcon|lsc
    listfile|lf SRC [TERM...]
    listpri|lsp [PRIORITY]
    listproj|lsprj
    move|mv NUMBER DEST [SRC]
    prepend|prep NUMBER "TEXT TO PREPEND"
    pri|p NUMBER PRIORITY
    replace NUMBER "UPDATED TODO"
    report
EOL
    }
    else {
        print <<'EOL';
Try 'todo.pl -h' for more information.
EOL
    }

    exit;
}

sub read_config {
    my ($file) = @_;

    my %config;
    open my $fh, '<', $file or die "Unable to open [$file]: $!";
LINE: while (<$fh>) {
        s/\r?\n$//xms;
        s/\s*\#.*$//xms;
        next LINE unless $_;

        if (s/^\s*export\s+//xms) {
            my ( $key, $value ) = /^([^=]+)\s*=\s*"?(.*?)"?\s*$/xms;
            if ($key) {
                foreach my $k ( keys %config ) {
                    $value =~ s/\$\Q$k\E/$config{$k}/gxms;
                    $value =~ s/\${\Q$k\E}/$config{$k}/gxms;
                }
                foreach my $k ( keys %ENV ) {
                    $value =~ s/\$\Q$k\E/$ENV{$k}/gxms;
                    $value =~ s/\${\Q$k\E}/$ENV{$k}/gxms;
                }
                $value =~ s/\$\w+//gxms;
                $value =~ s/\${\w+}//gxms;

                $config{$key} = $value;
            }
        }
    }
    close $fh;

    my %lc_config;
    foreach my $k ( keys %config ) {
        $lc_config{ lc($k) } = $config{$k};
    }

    return \%lc_config;
}
