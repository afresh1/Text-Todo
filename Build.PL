use strict;
use warnings;
use Module::Build;

# $AFresh1: Build.PL,v 1.6 2010/01/20 21:53:01 andrew Exp $

my $builder = Module::Build->new(
    module_name       => 'Text::Todo',
    license           => 'perl',
    dist_author       => 'Andrew Fresh <andrew@cpan.org>',
    dist_version_from => 'lib/Text/Todo.pm',
    requires          => {
        'Carp'              => 0,
        'Class::Std::Utils' => 0,
        'File::Spec'        => 0,
        'Test::More'        => 0.82,
        'version'           => 0,
    },
    add_to_cleanup => ['Text-Todo-*'],
);

$builder->create_build_script();
