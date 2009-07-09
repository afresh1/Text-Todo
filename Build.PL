use strict;
use warnings;
use Module::Build;
# $RedRiver$

my $builder = Module::Build->new(
    module_name         => 'Text::Todo',
    license             => 'perl',
    dist_author         => 'Andrew Fresh <andrew@cpan.org>',
    dist_version_from   => 'lib/Text/Todo.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Text-Todo-*' ],
);

$builder->create_build_script();
