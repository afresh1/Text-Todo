use Test::More tests => 3;

BEGIN {
	eval "use Test::Mojo";
	plan skip_all => "Test::Mojo required for testing dudelicious" if $@;

	use lib 'bin';
	require 'dudelicious.pl';
	Dudelicious->import;
}

my $app = Dudelicious::app;
$app->log->level('error');

my $t = Test::Mojo->new;

# Index page
$t->get_ok('/')->status_is(200)->content_like(qr/Funky/);
