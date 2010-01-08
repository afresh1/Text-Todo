package Text::Todo::Entry;

# $RedRiver: Entry.pm,v 1.8 2010/01/08 04:50:41 andrew Exp $

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

    # Aliases
    sub change  { _update_entry(@_) }
    sub depri   { _set_priority( @_, '' ) }
    sub pri     { priority(@_) }
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

    sub _set_priority {
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

        if ($new_pri) {
            return $self->_set_priority($new_pri);
        }

        return $priority_of{$ident};
    }

    sub prepend {
        my ( $self, $addition ) = @_;

        my $new = $self->text;
        my @new;

        $new =~ s/$priority_completion_regex//xms;

        if ( $self->done) {
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

        if ( $self->done) {
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

Text::Todo::Entry - [One line description of module's purpose here]


=head1 VERSION

This document describes Text::Todo::Entry version 0.0.1


=head1 SYNOPSIS

    use Text::Todo::Entry;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.

=head2 new

=head2 text

=head2 priority

=head2 contexts

=head2 in_context

=head2 projects

=head2 in_project

=head2 change

=head2 prepend

=head2 append

=head2 do

=head2 done


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Text::Todo::Entry requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

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
