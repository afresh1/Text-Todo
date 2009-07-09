use strict;
use warnings;
use ExtUtils::MakeMaker;
# $RedRiver$

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
