use strict;
use warnings;
use ExtUtils::MakeMaker;
# $AFresh1: Makefile.PL,v 1.1.1.1 2009/07/09 18:21:34 andrew Exp $

WriteMakefile(
    NAME                => 'Text::Todo',
    AUTHOR              => 'Andrew Fresh <andrew@cpan.org>',
    VERSION_FROM        => 'lib/Text/Todo.pm',
    ABSTRACT_FROM       => 'lib/Text/Todo.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Todo-*' },
);
