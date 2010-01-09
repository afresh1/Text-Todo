package Text::Todo;

# $RedRiver: Todo.pm,v 1.4 2010/01/06 20:07:16 andrew Exp $

use warnings;
use strict;
use Carp;

use Class::Std::Utils;
use Text::Todo::Entry;
use File::Spec;

use Data::Dumper;

use version; our $VERSION = qv('0.0.1');

{

    my %path_of;
    my %list_of;

    sub new {
        my ( $class, $options ) = @_;

        my $self = bless anon_scalar(), $class;
        my $ident = ident($self);

        $path_of{$ident} = {
            todo_dir    => undef,
            todo_file   => 'todo.txt',
            done_file   => undef,
            report_file => undef,
        };

        if ($options) {
            if ( ref $options eq 'HASH' ) {
                foreach my $opt ( keys %{$options} ) {
                    if ( exists $path_of{$ident}{$opt} ) {
                        $self->_path_to( $opt, $options->{$opt} );
                    }
                    else {
                        carp "Invalid option [$opt]";
                    }
                }
            }
            else {
                if ( -d $options ) {
                    $self->_path_to( 'todo_dir', $options );
                }
                elsif ( $options =~ /\.txt$/ixms ) {
                    $self->_path_to( 'todo_file', $options );
                }
                else {
                    carp "Unknown options [$options]";
                }
            }
        }

        my $file = $self->_path_to('todo_file');
        if ( defined $file && -e $file ) {
            $self->load();
        }

        return $self;
    }

    sub _path_to {
        my ( $self, $type, $path ) = @_;
        my $ident = ident($self);

        if ( $type eq 'todo_dir' ) {
            if ($path) {
                $path_of{$ident}{$type} = $path;
            }
            return $path_of{$ident}{$type};
        }

        if ($path) {
            my ( $volume, $directories, $file )
                = File::Spec->splitpath($path);
            $path_of{$ident}{$type} = $file;

            if ($volume) {
                $directories = File::Spec->catdir( $volume, $directories );
            }

            # XXX Should we save complete paths to each file, mebbe only if
            # the dirs are different?
            if ($directories) {
                $path_of{$ident}{todo_dir} = $directories;
            }
        }

        if ( $type =~ /(todo|done|report)_file/xms ) {
            if ( my ( $pre, $post )
                = $path_of{$ident}{$type} =~ /^(.*)$1(.*)\.txt$/ixms )
            {
                foreach my $f qw( todo done report ) {
                    if ( !defined $path_of{$ident}{ $f . '_file' } ) {
                        $path_of{$ident}{ $f . '_file' }
                            = $pre . $f . $post . '.txt';
                    }
                }
            }
        }

        if ( defined $path_of{$ident}{todo_dir} ) {
            return File::Spec->catfile( $path_of{$ident}{todo_dir},
                $path_of{$ident}{$type} );
        }

        return;
    }

    sub file {
        my ( $self, $file ) = @_;
        my $ident = ident($self);

        if ( defined $file && exists $path_of{$ident}{$file} ) {
            $file = $self->_path_to($file);
        }
        else {
            $file = $self->_path_to( 'todo_file', $file );
        }

        return $file;
    }

    sub load {
        my ( $self, $file ) = @_;
        my $ident = ident($self);

        $file = $self->file($file);

        if ( !defined $file ) {
            croak "todo file can't be found";
        }

        if ( !-e $file ) {
            carp "todo file [$file] does not exist";
            return;
        }

        my @list;
        my $line = 1;
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

        $file = $self->file($file);
        if ( !defined $file ) {
            croak "todo file can't be found";
        }

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

        my @list = @{ $list_of{$ident} };

        return wantarray ? @list : \@list;
    }

    sub listpri {
        my ($self) = @_;

        my @list = grep { $_->priority } $self->list;

        return wantarray ? @list : \@list;
    }

    sub add {
        my ( $self, $entry ) = @_;
        my $ident = ident($self);

        if ( !ref $entry ) {
            $entry = Text::Todo::Entry->new($entry);
        }
        elsif ( ref $entry ne 'Text::Todo::Entry' ) {
            croak(
                'entry is a ' . ref($entry) . ' not a Text::Todo::Entry!' );
        }

        push @{ $list_of{$ident} }, $entry;

        return $entry;
    }

    sub del { 
        my ( $self, $src ) = @_;
        my $ident = ident($self);

        my $id  = $self->_find_entry_id($src);

        my @list = $self->list;
        my $entry = splice( @list, $id, 1 );
        $list_of{$ident} = \@list;

        return $entry;
    }

    sub move {
        my ( $self, $entry, $dst ) = @_;
        my $ident = ident($self);

        my $src  = $self->_find_entry_id($entry);
        my @list = $self->list;

        splice( @list, $dst, 0, splice( @list, $src, 1 ) );

        $list_of{$ident} = \@list;

        return 1;
    }

    sub listproj { 
        my ( $self, $entry, $dst ) = @_;
        my $ident = ident($self);

        my %available_projects;
        foreach my $e ($self->list) {
            foreach my $p ( $e->projects ) {
                $available_projects{$p} = 1;
            }
        }

        my @projects = sort keys %available_projects;

        return wantarray ? @projects : \@projects;
    }

    sub archive  { carp "unsupported\n", return }

    sub addto    { carp "unsupported\n", return }
    sub listfile { carp "unsupported\n", return }

    sub _find_entry_id {
        my ( $self, $entry ) = @_;
        my $ident = ident($self);

        if ( ref $entry ) {
            if ( ref $entry ne 'Text::Todo::Entry' ) {
                croak(    'entry is a '
                        . ref($entry)
                        . ' not a Text::Todo::Entry!' );
            }

            my @list = $self->list;
            foreach my $id ( 0 .. $#list ) {
                if ( $list[$id] eq $entry ) {
                    return $id;
                }
            }
        }
        elsif ( $entry =~ /^\d+$/xms ) {
            return $entry;
        }

        croak "Invalid entry [$entry]!";
    }
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Text::Todo - Perl interface to todo_txt files


=head1 SYNOPSIS

    use Text::Todo;

=head1 DESCRIPTION

For more information see L<http://todotxt.com>

=head1 INTERFACE 

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

Text::Todo requires no configuration files or environment variables.

Someday it should be able to read and use the todo.sh config file.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

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
