package Text::Todo;

# $RedRiver: Todo.pm,v 1.2 2009/07/10 22:26:14 andrew Exp $

use warnings;
use strict;
use Carp;

use Class::Std::Utils;
use Text::Todo::Entry;

use version; our $VERSION = qv('0.0.1');

{

    my %file_of;
    my %list_of;

    sub new {
        my ( $class, $file ) = @_;

        my $self = bless anon_scalar(), $class;
        my $ident = ident($self);

        if ($file) { $self->load($file); }

        return $self;
    }

    sub file {
        my ( $self, $file ) = @_;
        my $ident = ident($self);

        if ($file) {
            $file_of{$ident} = $file;
        }

        return $file_of{$ident};
    }

    sub load {
        my ( $self, $file ) = @_;
        my $ident = ident($self);

        $file = $self->file($file) || croak 'load requires a filename';

        my @list;
        open my $fh, '<', $file or croak "Couldn't open [$file]: $!";
        while (<$fh>) {
            s/\r?\n$//xms;
            push @list, Text::Todo::Entry->new($_);
        }
        close $fh or croak "Couldn't close [$file]: $!";
        $list_of{$ident} = \@list;

        return 1;
    }

    sub save {
        my ( $self, $file ) = @_;
        my $ident = ident($self);

        $file = $self->file($file) || croak 'save requires a filename';

        open my $fh, '>', $file or croak "Couldn't open [$file]: $!";
        foreach my $e ( @{ $list_of{$ident} } ) {
            print {$fh} $e->text . "\n"
                or croak "Couldn't print to [$file]: $!";
        }
        close $fh or croak "Couldn't close [$file]: $!";

        return 1;
    }

    sub list {
        my ($self) = @_;
        my $ident = ident($self);
        return if !$list_of{$ident};

        return $list_of{$ident};

        #my $id = 1;
        #my @l;
        #foreach my $e ( @{ $list_of{$ident} } ) {
        #    push @l, $e; #{ %{$e}, id => $id };
        #    $id++;
        #}
        #
        #my @list = sort { $a->priority cmp $b->priority }
        #    grep { defined $_->priority } @l;
        #
        #push @list, grep { !defined $_->priority } @l;
        #
        #return \@list;
    }

    sub add {
        my ( $self, $entry ) = @_;
        my $ident = ident($self);

        if ( ref $entry ) {
            if ( ref $entry ne 'Text::Todo::Entry' ) {
                croak(    'entry is a '
                        . ref($entry)
                        . ' not a Text::Todo::Entry!' );
            }
        }
        else {
            $entry = Text::Todo::Entry->new($entry);
        }

        push @{ $list_of{$ident} }, $entry;

        return $entry;
    }
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Text::Todo - [One line description of module's purpose here]


=head1 VERSION

This document describes Text::Todo version 0.0.1


=head1 SYNOPSIS

    use Text::Todo;

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

=head2 load

=head2 save

=head2 file

=head2 list

=head2 add

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
  
Text::Todo requires no configuration files or environment variables.


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
