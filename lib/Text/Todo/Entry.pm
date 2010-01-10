package Text::Todo::Entry;

# $RedRiver: Entry.pm,v 1.11 2010/01/09 07:08:45 andrew Exp $

use warnings;
use strict;
use Carp;

use Class::Std::Utils;
use List::Util qw/ first /;

use version; our $VERSION = qv('0.0.1');

{
    my %text_of;

    my %tags_of;
    my %priority_of;
    my %completion_status_of;

    my %tags = (
        context => q{@},
        project => q{+},
    );

    # XXX Should the completion (x) be case sensitive?
    my $priority_completion_regex = qr/
        ^ \s*
        (?i:   (x)        \s+)?
        (?i:\( ([A-Z]) \) \s+)?
    /xms;

    for my $tag ( keys %tags ) {
        ## no critic strict
        no strict 'refs';    # Violates use strict, but allows code generation
        ## use critic

        *{ $tag . 's' } = sub {
            my ($self) = @_;
            return $self->_tags($tag);
        };

        *{ 'in_' . $tag } = sub {
            my ( $self, $item ) = @_;
            return $self->_is_in( $tag . 's', $item );
        };
    }

    sub replace { _update_entry(@_) }

    sub new {
        my ( $class, $text ) = @_;

        my $self = bless anon_scalar(), $class;
        my $ident = ident($self);

        $self->_update_entry($text);

        return $self;
    }

    sub _update_entry {
        my ( $self, $text ) = @_;
        my $ident = ident($self);

        $text = defined $text ? $text : q{};

        $text_of{$ident} = $text;

        foreach my $tag ( keys %tags ) {
            my $symbol = quotemeta $tags{$tag};
            $tags_of{$ident}{$tag} = { map { $_ => q{} }
                    $text =~ / (?:^|\s) $symbol  (\S+)/gxms };
        }
        ( $completion_status_of{$ident}, $priority_of{$ident} )
            = $text =~ / $priority_completion_regex /xms;

        return 1;
    }

    sub _tags {
        my ( $self, $tag ) = @_;
        my $ident = ident($self);

        my @tags = sort keys %{ $tags_of{$ident}{$tag} };
        return wantarray ? @tags : \@tags;
    }

    sub _is_in {
        my ( $self, $tags, $item ) = @_;
        return defined first { $_ eq $item } $self->$tags;
    }

    sub text {
        my ($self) = @_;
        my $ident = ident($self);

        return $text_of{$ident};
    }

    sub depri { pri( $_[0], '' ) }

    sub pri {
        my ( $self, $new_pri ) = @_;
        my $ident = ident($self);

        if ( $new_pri !~ /^[a-zA-Z]?$/xms ) {
            croak "Invalid priority [$new_pri]";
        }

        $priority_of{$ident} = $new_pri;

        return $self->prepend();
    }

    sub priority {
        my ( $self, $new_pri ) = @_;
        my $ident = ident($self);

        return $priority_of{$ident};
    }

    sub prepend {
        my ( $self, $addition ) = @_;

        my $new = $self->text;
        my @new;

        $new =~ s/$priority_completion_regex//xms;

        if ( $self->done ) {
            push @new, $self->done;
        }

        if ( $self->priority ) {
            push @new, '(' . $self->priority . ')';
        }

        if ( defined $addition && length $addition ) {
            push @new, $addition;
        }

        return $self->_update_entry( join q{ }, @new, $new );
    }

    sub append {
        my ( $self, $addition ) = @_;
        return $self->_update_entry( join q{ }, $self->text, $addition );
    }

    sub do {
        my ($self) = @_;
        my $ident = ident($self);

        if ( $self->done ) {
            return 1;
        }

        $completion_status_of{$ident} = 'x';

        return $self->prepend();
    }

    sub done {
        my ($self) = @_;
        my $ident = ident($self);

        return $completion_status_of{$ident};
    }

}
1;    # Magic true value required at end of module
__END__

=head1 NAME

Text::Todo::Entry - An object for manipulating an entry on a Text::Todo list


=head1 VERSION

Since the $VERSION can't be automatically included, 
here is the RCS Id instead, you'll have to look up $VERSION.

    $Id: Entry.pm,v 1.12 2010/01/10 00:13:14 andrew Exp $


=head1 SYNOPSIS

    use Text::Todo::Entry;

    my $entry = Text::Todo::Entry->new('text of entry');

    $entry->append('+project');

    if ($entry->in_project('project') && ! $entry->priority) {
        print $entry->text, "\n";
    }


=head1 DESCRIPTION

This module creates entries in a Text::Todo list.
It allows you to retrieve information about them and modify them.

For more information see L<http://todotxt.com>


=head1 INTERFACE 

=head2 new

Creates an entry that can be manipulated.

    my $entry = Text::Todo::Entry->new(['text of entry']);

If you don't pass any text, creates a blank entry. 

=head2 text

Returns the text of the entry.  

    print $entry->text, "\n";

=head2 pri

Sets the priority of an entry. If the priority is set to an empty string,
clears the priority.

    $entry->pri('B');

Acceptible entries are an empty string, A-Z or a-z. Anything else will cause
an error.

=head2 depri

A convenience function that unsets priority by calling pri('').

    $entry->depri;

=head2 priority

Returns the priority of an entry which may be an empty string if it is 

    my $priority = $entry->priority;

=head2 tags

Each tag type generates two accessor functions {tag}s and in_{tag}.

Current tags are context (@) and project (+).

=over

=item {tag}s

    @tags = $entry->{tag}s;

=item in_{tag}

returns true if $entry is in the tag, false if not.

    if ($entry->in_{tag}('tag')) {
        # do something
    }

=back

=head3 context

These are matched as a word beginning with @.

=over

=item contexts

=item in_context

=back

=head3 project

This is matched as a word beginning with +.

=over

=item projects

=item in_project

=back

=head2 replace

Replaces the text of an entry with completely new text.  Useful if there has
been manual modification of the entry or just a new direction.

    $entry->replace('replacment text');

=head2 prepend

Attaches text (with a trailing space) to the beginning of an entry.  Puts it
after the done() "x" and the priority() letter.

    $entry->prepend('NEED HELP');

=head2 append

Adds text to the end of an entry.  
Useful for adding tags, or just additional information.

    $entry->append('@specific_store');

=head2 do

Marks an entry as completed.

    $entry->do;

Does this by prepending an 'x' to the beginning of the entry.

=head2 done

Returns true if an entry is marked complete and false if not.

    if (!$entry->done) {
        # remind me to do it
    }


=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

Text::Todo::Entry requires no configuration files or environment variables.


=head1 DEPENDENCIES 

Class::Std::Utils
List::Util
version


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Known limitations:

Sometimes leading whitespace may get screwed up when making changes.  It
doesn't seem to be particularly a problem, but if you use whitespace to indent
entries for some reason it could be.

Please report any bugs or feature requests to
C<bug-text-todo@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Andrew Fresh  C<< <andrew@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Andrew Fresh C<< <andrew@cpan.org> >>. All rights reserved.

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
