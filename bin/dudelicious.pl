#!/usr/bin/perl

package Dudelicious;

use Data::Dumper;
use version; our $VERSION = qv('0.1.0');

BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../lib";
    use lib "$FindBin::Bin/../mojo/lib";
}

use Carp qw/ carp croak /;
use Digest::MD5 qw/ md5_hex /;
use Text::Todo;

use Mojolicious::Lite;
use Mojo::JSON;

app->home->parse( $ENV{DUDELICIOUS_HOME} ) if $ENV{DUDELICIOUS_HOME};

plugin 'json_config' => {
    file    => 'dudelicious.conf',
    default => { todo_dir => $ENV{DUDELICIOUS_HOME} || '.', },
};

get '/' => sub {
    my $self = shift;

    my $dir = _todo($self)->file('todo_dir');
    opendir my $dh, $dir or croak "Unable to opendir $dir: $!";
    my @files = grep {/\.te?xt$/ixms} readdir $dh;
    closedir $dh;

    $self->render( files => \@files, layout => 'todotxt' );
} => 'index';

get '/l/:file' => sub {
    my $self   = shift;
    my $file   = $self->stash('file') . '.txt';
    my $format = $self->stash('format') || 'html';
    my $list   = _get_list( $self, $file );

    if ( $format eq 'json' ) {
        $self->render_json($list);
    }
    else {
        $self->render( list => $list, layout => 'todotxt' );
    }
} => 'list';

get '/l/:file/e/:line' => sub {
    my $self   = shift;
    my $file   = $self->stash('file') . '.txt';
    my $format = $self->stash('format') || 'html';
    my $entry  = _get_list( $self, $file )->[ $self->stash('line') - 1 ];

    if ( $format eq 'json' ) {
        $self->render_json($entry);
    }
    else {
        $self->render( entry => $entry, layout => 'todotxt' );
    }
} => 'entry';

app->start unless caller();

sub _todo {
    my ($c) = @_;

    if ( !$c->stash('todo') ) {
        my $todo = Text::Todo->new( $c->stash('config') );
        $c->stash( 'todo' => $todo );
    }

    return $c->stash('todo');
}

sub _get_list {
    my ( $c, $file ) = @_;

    my $line = 1;
    return [
        map ( { line => $line++,
                md5  => md5_hex( $_->text ),
                text => $_->text,
                done => $_->done,
            },
            _todo($c)->listfile($file),
        )
    ];
}

__DATA__

@@ list.txt.ep
% foreach my $entry (@{ $list }) {
%==  include 'entry', entry => $entry;
% }

@@ entry.txt.ep
<%= $entry->{text} %>

@@ layouts/todotxt.txt.ep
%= content

@@ index.html.ep
% foreach my $file (@{ $files }) {
<%== $file %> <br />
% }

@@ list.html.ep
<h1><%= $file %></h1>
<ol>
% foreach my $entry (@{ $list }) {
    <li>
%=  include 'entry', entry => $entry;
    </li>
% }
</ol>

@@ entry.html.ep
<%= $entry->{text} %>

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

    $Id: dudelicious.pl,v 1.8 2010/04/30 17:17:40 andrew Exp $

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
