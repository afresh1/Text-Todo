#!/usr/bin/perl
# $RedRiver$
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
use Text::Todo;

use version; our $VERSION = qv('0.0.1');

my $todo = Text::Todo->new('t/todo1.txt') or die $!;

foreach my $entry ( sort { lc( $a->text ) cmp lc( $b->text ) } $todo->list ) {

    #print Dumper $entry;
    print $entry->text, "\n";
}
