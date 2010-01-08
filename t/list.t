#===============================================================================
#
#         FILE:  list.t
#
#  DESCRIPTION:  Test list commands
#
#
#       AUTHOR:  Andrew Fresh (AAF), andrew@cpan.org
#      COMPANY:  Red River Communications
#      CREATED:  01/07/10 19:11
#     REVISION:  $RedRiver$
#===============================================================================

use strict;
use warnings;

use Test::More tests => 2;

my $class = 'Text::Todo';

BEGIN: { use_ok( $class, "use $class" ) }

diag("Testing entry $class $Text::Todo::VERSION");

my $e = new_ok( $class, [ 't/todo.list.txt' ] );

my %commands = (
    add      => {},
    archive  => {},
    del      => {},
    list     => {},
    listall  => {},
    listcon  => {},
    listfile => {},
    listpri  => {},
    listproj => {},
    move     => {},
    replace  => {},
    report   => {},
);

my %aliases = (
    a     => 'add',
    rm    => 'del',
    ls    => 'list',
    lsa   => 'listall',
    lsc   => 'listcon',
    lf    => 'listfile',
    lspri => 'listpri',
    lsprj => 'listproj',
    mv    => 'move',
);
