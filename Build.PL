use strict;
use warnings;
use Module::Build;
# $RedRiver: Build.PL,v 1.1.1.1 2009/07/09 18:21:34 andrew Exp $

my $builder = Module::Build->new(
    module_name         => 'Text::Todo',
    license             => 'perl',
    dist_author         => 'Andrew Fresh <andrew@cpan.org>',
    dist_version_from   => 'lib/Text/Todo.pm',
    requires => {
        'Test::More' => 0,
        'Carp' => 0,
        'Class::Std::Utils' => 0,
        'File::Spec' => 0,
        'List::Util' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Text-Todo-*' ],
);

$builder->create_build_script();
