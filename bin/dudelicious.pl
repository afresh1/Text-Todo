#!/usr/bin/perl

package Dudelicious;

use 5.010;
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

app->renderer->add_helper(
    todo => sub {
        my ($self) = @_;
        state $todo = Text::Todo->new( $self->stash('config') );

        my $file = $self->stash('file');
        if ($file) {
            $file =~ s/(?:\.txt)?$/\.txt/ixms;
            $todo->load($file);
        }

        return $todo;
    }
);

app->renderer->add_helper(
    get_list => sub {
        my ($self) = @_;

        my $line = 1;
        return [
            map {
                line     => $line++,
                    md5  => md5_hex( $_->text ),
                    text => $_->text,
                    done => $_->done,
            },
            $self->helper('todo')->list
        ];
    }
);

get '/' => sub {
    my $self = shift;

    my $dir = $self->helper('todo')->file('todo_dir');
    opendir my $dh, $dir or croak "Unable to opendir $dir: $!";
    my @files = grep {/\.te?xt$/ixms} readdir $dh;
    closedir $dh;

    $self->render( files => \@files, layout => 'todotxt' );
} => 'index';

get '/todotxt' => 'todotxt';

get '/l/:file' => sub {
    my $self = shift;

    my $format = $self->stash('format') || 'html';

    if ( $format eq 'json' ) {
        $self->render_json( $self->helper('get_list') );
    }
    else {
        $self->render(
            list   => $self->helper('get_list'),
            layout => 'todotxt'
        );
    }
} => 'list';

get '/l/:file/e/:line' => sub {
    my $self = shift;

    my $format = $self->stash('format') || 'html';
    my $entry = $self->helper('get_list')->[ $self->stash('line') - 1 ];

    if ( $format eq 'json' ) {
        $self->render_json($entry);
    }
    else {
        $self->render( entry => $entry, layout => 'todotxt' );
    }
} => 'entry';

get '/l/:file/t' => sub {
    my $self = shift;

    my $format = $self->stash('format') || 'html';

    if ( $format eq 'json' ) {
        $self->render_json( $self->helper('todo')->known_tags );
    }
    else {
        $self->render(
            tags   => $self->helper('todo')->known_tags,
            layout => 'todotxt'
        );
    }
} => 'tags';

get '/l/:file/t/:tag' => sub {
    my $self = shift;

    my $format = $self->stash('format') || 'html';
    my $items  = $self->helper('todo')->listtag( $self->stash('tag') );

    if ( $format eq 'json' ) {
        $self->render_json($items);
    }
    else {
        $self->render( items => $items, layout => 'todotxt' );
    }
} => 'tag';

app->start if !caller();

1;
__DATA__

@@ list.txt.ep
% foreach my $entry (@{ $list }) {
%==  include 'entry', entry => $entry;
% }

@@ entry.txt.ep
<%= $entry->{text} %>

@@ tags.txt.ep
% foreach my $tag (keys %{ $tags }) {
<%= $tag %>, <%= $tags->{$tag} %>
% }

@@ tag.txt.ep
# <%= $tag %>
% foreach my $item (@{ $items}) {
<%= $item %>
% }

@@ layouts/todotxt.txt.ep
%= content

@@ index.html.ep
% foreach my $file (@{ $files }) {
% my ($basename) = $file =~ /^(.*?)(?:\.[^\.]+)?$/xms;
<a href="<%= url_for 'list' %>/<%= $basename %>"><%= $file %></a><br />
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

@@ tags.html.ep
% foreach my $tag (keys%{ $tags }) {
<a href="<%= url_for 'tag', format => '' %>/<%= $tag %>"><%= $tag %> == <%= $tags->{$tag} %></a><br />
% }

@@ tag.html.ep
<h2><%= $tag %></h2>
% foreach my $item (@{ $items }) {
<%= $item %><br />
% }

@@ layouts/todotxt.html.ep
<!doctype html><html>
    <head>
        <title>Funky!</title>
        <link rel="stylesheet" href="<%= url_for 'todotxt', format => 'css' %>">
    </head>
    <body><%== content %></body>
</html>

@@ todotxt.css.ep
body {
        background: LightGoldenRodYellow;
        color: DarkSlateBlue;
}

.inplaceeditor-saving {
        background: url(images/saving.gif) bottom right no-repeat;
}


__END__

=head1 NAME

dudelicious - A Mojolicous interface to your todotxt files

=head1 VERSION

Since the $VERSION can't be automatically included, 
here is the RCS Id instead, you'll have to look up $VERSION.

    $Id: dudelicious.pl,v 1.14 2010/05/01 21:47:51 andrew Exp $

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
