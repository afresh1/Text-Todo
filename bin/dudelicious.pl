#!/usr/bin/env perl

package Dudelicious;

use version; our $VERSION = qv('0.1.0');

BEGIN { use FindBin; use lib "$FindBin::Bin/mojo/lib" }

use Carp qw/ carp croak /;

use Mojolicious::Lite;
use Text::Todo;

use Data::Dumper;

my %config = ( todo_dir => $ENV{DUDELICIOUS_HOME} || '.', );

app->home->parse( $ENV{DUDELICIOUS_HOME} ) if $ENV{DUDELICIOUS_HOME};
_read_config_from_file( app->home->rel_file('dudelicious.conf') );

plugin 'default_helpers';

my $todo = Text::Todo->new( \%config );

get '/' => sub {
    my $self = shift;

    my $dir = $todo->file('todo_dir');
    opendir my $dh, $dir or croak "Unable to opendir $dir: $!";
    my @files = grep {/\.te?xt$/ixms} readdir $dh;
    closedir $dh;

    $self->render( files => \@files, layout => 'todotxt' );
} => 'index';

get '/l/:file' => sub {
    my $self = shift;
    my $file = $self->stash('file') . '.txt';

    $self->render( list => [ $todo->listfile($file) ], layout => 'todotxt' );
} => 'list';

get '/l/:file/e/:entry' => sub {
    my $self  = shift;
    my $file  = $self->stash('file') . '.txt';
    my $entry = $self->stash('entry') - 1;

    $self->render(
        entry  => $todo->listfile($file)->[$entry],
        layout => 'todotxt'
    );
} => 'entry';

app->start unless caller();

sub _read_config_from_file {
    my ($conf_file) = @_;

    app->log->debug("Reading configuration from $conf_file.");

    if ( -e $conf_file ) {
        if ( open FILE, "<", $conf_file ) {
            my @lines = <FILE>;
            close FILE;

            my $line = '';
            foreach my $l (@lines) {
                next if $l =~ m/^\s*#/;
                $line .= $l;
            }

            my $json = Mojo::JSON->new;
            my $json_config = $json->decode($line) || {};
            die $json->error if !$json_config && $json->error;

            %config = ( %config, %$json_config );

            unshift @INC, $_
                for (
                ref $config{perl5lib} eq 'ARRAY'
                ? @{ $config{perl5lib} }
                : $config{perl5lib}
                );
        }
    }
    else {
        app->log->debug("Configuration [$conf_file] is not available.");
    }

    $ENV{SCRIPT_NAME} = $config{base} if defined $config{base};

    # set proper templates base dir, if defined
    app->renderer->root( app->home->rel_dir( $config{templatesdir} ) )
        if defined $config{templatesdir};

    # set proper public base dir, if defined
    app->static->root( app->home->rel_dir( $config{publicdir} ) )
        if defined $config{publicdir};
}

__DATA__

@@ list.txt.ep
% foreach my $i (0..$#{ $list }) {
%==  include 'entry', entry => $list->[$i], line => $i + 1;
% }

@@ entry.txt.ep
<%= $entry->text %>

@@ layouts/todotxt.txt.ep
%= content

@@ index.html.ep
% foreach my $file (@{ $files }) {
<%== $file %> <br />
% }

@@ list.html.ep
<h1><%= $file %></h1>
<ol>
% foreach my $i (0..$#{ $list }) {
    <li>
%=  include 'entry', entry => $list->[$i], line => $i + 1;
    </li>
% }
</ol>

@@ entry.html.ep
<%= $entry->text %>

@@ layouts/todotxt.html.ep
<!doctype html><html>
    <head><title>Funky!</title></head>
    <body><%== content %></body>
</html>


__END__

=head1 NAME

dudelicious - A Mojolicous interface to your todotxt files

=head1 VERSION

Since the $VERSION can't be automatically included, 
here is the RCS Id instead, you'll have to look up $VERSION.

    $Id: dudelicious.pl,v 1.5 2010/04/29 04:50:33 andrew Exp $

=head1 SYNOPSIS

    dudelicious daemon

Then browse to http://localhost:3000/

=head1 DESCRIPTION

A Mojolicous web app for access to your todotxt files

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

=head1 DIAGNOSTICS

=head1 DEPENDENCIES 

Perl Modules:

=over

=item Text::Todo

=item Mojolicous::Lite

=item version

=back


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Andrew Fresh  C<< <andrew@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Andrew Fresh C<< <andrew@cpan.org> >>. All rights reserved.

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
