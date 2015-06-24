use strict;
use warnings;

use Text::Todo;
use Text::Todo::Addon;

package Text::Todo::Client;
use Class::Tiny qw( config ), {
    log  => sub { sub { print @_ } },
    todo => sub { Text::Todo->new( $_[0]->config ) },
    date => sub { \&_date },
};

use Carp;

sub _date {
    use Time::localtime;

    my $year = localtime->year() + 1900;
    my $month = localtime->mon() + 1;
    my $day = localtime->mday();

    return sprintf( "%d-%02d-%02d", $year, $month, $day );
}

sub _get_prefix {
    my ( $self, $file ) = @_;

    $file = $self->config->{todo_file} unless defined $file;

    use File::Basename;
    ( $file ) = fileparse( $file, qr/\.[^.]*/ );
    return uc $file;
}

sub _prepare_entry {
    my ( $self, @entry ) = @_;

    @entry = map { split "\r" } @entry; # eat CR like todo.sh does
    	
    my $entry = join q{ }, @entry;

    if ( $self->config->{ lc 'TODOTXT_DATE_ON_ADD' } ) {
	if ( $entry =~ /^(\([A-Z]\) )(.*)$/ ) {
	    $entry = $1 . $self->date->() . " $2";
	} else {
	    $entry = $self->date->() . " $entry";
	}
    }
    
    return $entry;
}
    

sub add {
    my ( $self, @entry ) = @_;
    if ( !@entry ) {
        croak "usage: todo.pl add 'item'\n";
    }

    my $entry = $self->_prepare_entry( @entry );

    if ( $self->todo->add($entry) && $self->todo->save ) {
        my @list  = $self->todo->list;
        my $lines = scalar @list;

	my $prefix = $self->_get_prefix;
	$self->log->( "$lines $entry\n$prefix: $lines added.\n" );

        return $lines;
    }
    croak "Unable to add [$entry]\n";
}

sub addto {
    my ( $self, $file, @entry ) = @_;
    if ( !( $file && @entry ) ) {
        die "usage: todo.pl addto DEST 'TODO ITEM'\n";
    }

    $file = $self->todo->file($file);

    die "TODO: Destination file $file does not exist.\n" unless -f $file;

    my $entry = $self->_prepare_entry( @entry );

    if ( $self->todo->addto( $file, $entry ) ) {
        my @list  = $self->todo->listfile($file);
        my $lines = scalar @list;

	my $prefix = $self->_get_prefix( $file );
	$self->log->( "$lines $entry\n$prefix: $lines added.\n" );

        return $lines;
    }
    die "Unable to add [$entry]\n";
}

sub append {
    my ( $self, $line, @text ) = @_;
    if ( !( $line && @text && $line =~ /^\d+$/xms ) ) {
        die 'usage: todo.pl append ITEM# "TEXT TO APPEND"' . "\n";
    }

    my $text = join q{ }, @text;

    my $entry = $self->todo->list->[ $line - 1 ];

    die $self->_get_prefix . ": No task $line.\n" unless defined $entry;

    if ( $entry->append($text) && $self->todo->save ) {
        return $self->log->( "$line ", $entry->text, "\n" );
    }
    croak "Unable to append\n";
}

sub archive {
    my ( $self ) = @_;

    my $file = $self->todo->file;

    my @archived = $self->todo->archive;
    $self->log->( $_->text, "\n" ) for @archived;

    return $self->log->( $self->_get_prefix, ": $file archived.\n" );
}

sub _getch {
    use POSIX qw(:termios_h);

    my $fd_stdin = fileno(STDIN);
    my $term = POSIX::Termios->new();
    $term->getattr($fd_stdin);
    my $oterm = $term->getlflag();

    my $echo     = ECHO | ECHOK | ICANON;
    my $noecho   = $oterm & ~$echo;

    $term->setlflag($noecho);
    $term->setcc(VTIME, 1);
    $term->setattr($fd_stdin, TCSANOW);

    my $key = getc(STDIN);

    $term->setlflag($oterm);
    $term->setcc(VTIME, 0);
    $term->setattr($fd_stdin, TCSANOW);

    return $key;
}

sub del {
    my ( $self, $line, $term ) = @_;
    if ( !( $line && $line =~ /^\d+$/xms ) ) {
        die "usage: todo.pl del ITEM# [TERM]\n";
    }

    my $prefix = $self->_get_prefix;
    die "$prefix: No task $line.\n" unless defined $self->todo->list;
    my $entry = $self->todo->list->[ $line - 1 ];
    die "$prefix: No task $line.\n" unless defined $entry;
    die "$prefix: No task $line.\n" if $entry->text =~ /^$/;

    unless ( defined $term || $self->config->{lc 'TODOTXT_FORCE'} ) {
	$self->log->( 'Delete \'', $entry->text . "'?  (y/n)\n" );
	my $key = _getch();
	return if $key ne 'y';
    }

    if ( defined $term ) {
	my ( $text, $replacement ) = ( $entry->text ) x 2;

	die "$line $text\n$prefix: '$term' not found; no removal done.\n"
	    unless $text =~ quotemeta( $term );

	$replacement =~ s/$term//g;
	$replacement = join ' ', split(' ', $replacement);
	if ( $entry->replace( $replacement ) && $self->todo->save ) {
	    return $self->log->(
		"$line $text\n", "$prefix: Removed '$term' from task.\n",
		"$line ", $entry->text, "\n" );
	} else {
	    die "Unable to delete entry\n";
	}
    }

    unless ( $self->config->{ lc 'TODOTXT_PRESERVE_LINE_NUMBERS' } ) {
	for my $e ( $self->todo->list ) {
	    if ( $e->text =~ /^$/ ) {
		$self->todo->del( $e ) or die "Unable to delete entry\n";
	    }
	}
        if ( $self->todo->del($entry) && $self->todo->save ) {
            return $self->log->(
		"$line ", $entry->text, "\n$prefix: $line deleted.\n" );
        }
    }
    else {
        my $text = $entry->text;
        if ( $entry->replace(q{}) && $self->todo->save ) {
            return $self->log->(
		"$line ", $text, "\n$prefix: $line deleted.\n" );
        }
    }

    die "Unable to delete entry\n";
}

sub depri {
    my ( $self, @args ) = @_;

    my @lines;
    for ( @args ) {
	push @lines, $_ for split /,/;
    }

    my $usage = 'usage: todo.pl depri ITEM#[, ITEM#, ITEM#, ...]' . "\n";
    die $usage unless @lines;

    my $prefix = $self->_get_prefix;

    for my $line ( @lines ) {
	die $usage if $line !~ /^\d+$/;
	die "$prefix: No task $line.\n" unless defined $self->todo->list;

	my $entry = $self->todo->list->[ $line - 1 ];

	die "$prefix: No task $line.\n" unless defined $entry;

	unless ( $entry->priority ) {
	    $self->log->( "$prefix: $line is not prioritized.\n" );
	    next;
	}

	if ( $entry->depri && $self->todo->save ) {
	    my $text = $entry->text;
	    $self->log->( "$line $text\n$prefix: $line deprioritized.\n" );
	} else {
	    croak "Unable to deprioritize entry\n";
	}
    }
    return 1;
}

sub do {
    my ( $self, @args ) = @_;

    my @lines;
    for ( @args ) {
	push @lines, $_ for split /,/;
    }
	
    my $usage = 'usage: todo.pl do ITEM#[, ITEM#, ITEM#, ...]' . "\n";
    die $usage unless @lines;

    for my $line ( @lines ) {
	die $usage if $line !~ /^\d+$/;
	my $prefix = $self->_get_prefix;

	die "$prefix: No task $line\n" unless defined $self->todo->list;
	my $entry = $self->todo->list->[ $line - 1 ];

	die "$prefix: No task $line\n" unless defined $entry;

	if ( $entry->done ) {
	    $self->log->( "$prefix: $line is already marked done.\n" );
	    next;
	}

	if ( $entry->do && $self->todo->save ) {
	    $self->log->(
		"$line ", $entry->text, "\n$prefix: $line marked as done.\n" );
	} else {
	    croak "Unable to mark as done\n";
	}
    }

    if ( $self->config->{ lc 'TODOTXT_AUTO_ARCHIVE' } ) {
	return $self->archive;
    }
    return 1;
}

sub help {
    my ($self, @action_names) = @_;

    if ( @action_names ) {
	for my $an ( @action_names ) {
	    my $addon = Text::Todo::Addon::for_name( $self->config, $an );
	    if ( $addon ) {
		$addon->( 'usage' );
	    } elsif ( my $ah = Text::Todo::Help::action_help( $an ) ) {
		$self->log->( "$$ah\n" );
	    } else {
		die "TODO: No action \"${an}\" exists.\n";
	    }
	}
	return;
    }

    # use a pager if one is available
    if (-t STDOUT) {
	my $pager = $ENV{PAGER} || "less";
	if ( system( "which $pager >/dev/null 2>&1" ) == 0 ) {
	    open(STDOUT, "| $pager");
	}
    }

    Text::Todo::Help::options_help();
    my $ah = Text::Todo::Help::action_help();
    $self->log->( "$$ah" );

    my $addons = {};
    Text::Todo::Addon::get_all( $self->config, $addons );
    if ( $addons ) {
    	$self->log->( "  Add-on Actions:\n" );
    	$addons->{ $_ }->( 'usage' ) for sort keys %$addons;
    }	
    close STDOUT;
}

sub list {
    my ( $self, @terms ) = @_;

    my @list = _number_list( undef, $self->todo->list );
    my $shown = $self->_show_sorted_list( \@terms, @list );

    return $self->_show_list_footer( shown => $shown, total => scalar @list );
}

sub listaddons {
    my ($self) = @_;
    my $addons = {};
    Text::Todo::Addon::get_all( $self->config, $addons );
    if ( $addons ) {
	$self->log->( "$_\n" ) for sort keys %$addons;
    }
}

sub listall {
    my ( $self, @terms ) = @_;

    my $next = 0;
    my @todo_list = _number_list( undef, $self->todo->listfile('todo_file') );
    my @done_list = _number_list(
	sub { 0 },
	$self->todo->listfile('done_file') );

    my @list = ( @todo_list, @done_list );
    my $shown = $self->_show_sorted_list( \@terms, @list );

    my $log = $self->log;
    $self->log( sub {} ); #suppress output
    my $task_num = $self->_show_sorted_list( \@terms, @todo_list );
    my $done_num = $self->_show_sorted_list( \@terms, @done_list );
    $self->log( $log ); #restore output

    $self->_show_list_footer(shown => $task_num, total => scalar @todo_list);
    $self->_show_list_footer(
	shown          => $done_num,
	total          => scalar @done_list,
	file           => $self->todo->file( 'done_file' ),
	with_separator => 0
	);
    my $total = @list;
    $self->log->( "total $shown of $total tasks shown\n" );

    return 1;
}

sub listcon {
    my ($self, @terms) = @_;
    return $self->log->( map {"\@$_\n"} $self->todo->listcon ) unless @terms;

    return $self->log->(
	map {"\@$_\n"} $self->_match_tag_type( context => @terms ) );
}

sub listfile {
    my ( $self, $file, @terms ) = @_;
    if ( !$file ) {
	my $todo_dir = $self->config->{todo_dir};
	opendir( my $dh, $todo_dir )
	    or croak( "Unable to opendir [$todo_dir]: $!" );

	while ( $file = readdir( $dh ) ) {
	    $self->log->( "$file\n" ) if $file =~ /\.txt$/;
	}
	closedir $dh;

	return;
    }

    my @list = _number_list( undef, $self->todo->listfile($file) );
    my $shown = $self->_show_sorted_list( \@terms, @list );

    return $self->_show_list_footer(
	shown => $shown, total => scalar @list, file => $file );
}

sub listpri {
    my ( $self, $pri, @terms ) = @_;

    my @list = _number_list( undef, $self->todo->listfile('todo_file') );
    my @pri_list;
    if ($pri) {
	my $term = $pri;
        $pri = uc $pri;
        if ( $pri =~ /^[[:upper:]]$/xms ) {
	    @pri_list = grep {
		defined $_->{entry}->priority
		    && $_->{entry}->priority eq $pri
	    } @list; 
        } elsif ( $pri =~ /^([[:upper:]])-([[:upper:]])$/ ) {
	    my ( $lower, $upper ) = ( $1, $2 );#should it be min(1,2),max(1,2)?
	    @pri_list = grep {
		defined $_->{entry}->priority
		    && $_->{entry}->priority ge $lower
		    && $_->{entry}->priority le $upper
	    } @list;
        } else {
	    # $pri is actually a term
	    unshift @terms, $term;
	    @pri_list = grep { $_->{entry}->priority } @list;
	}
    } else {
	# no priority or term. list all prioritized items.
        @pri_list = grep { $_->{entry}->priority } @list;
    }

    my $match = sub {
	my ( $line, $entry ) = ( $_->{line}, $_->{entry} );
	for ( @terms ) {
	    my $term = $_;
	    if ( $term =~ /^-/ ) {
		$term =~ s/^-//;
		return 0 if $entry->text =~ /$term/;
	    } else {
		return 0 if $entry->text !~ /$term/;
	    }
	}
	return 1;
    };
    my @fl = grep { $match->( $_ ) } @pri_list;

    my $shown = $self->_show_sorted_list( undef, @fl );

    return $self->_show_list_footer( shown => $shown, total => scalar @list );
}

sub listproj {
    my ($self, @terms) = @_;
    return $self->log->( map {"\+$_\n"} $self->todo->listproj ) unless @terms;

    return $self->log->(
	map {"\+$_\n"} $self->_match_tag_type( project => @terms ) );
}

## no critic 'sigal'
sub move { return &unsupported }
## use critic

sub prepend {
    my ( $self, $line, @text ) = @_;
    if ( !( $line && @text && $line =~ /^\d+$/xms ) ) {
        die 'usage: todo.pl prepend ITEM# "TEXT TO PREPEND"' . "\n";
    }

    my $text = join q{ }, @text;

    my $entry = $self->todo->list->[ $line - 1 ];

    if ( $entry->prepend($text) && $self->todo->save ) {
        return $self->log->( "$line ", $entry->text , "\n" );
    }
    die "Unable to prepend\n";
}

sub pri {
    my ( $self, $line, $priority ) = @_;
    my $error = 'usage: todo.pl pri ITEM# PRIORITY'
      . "\nnote: PRIORITY must be anywhere from A to Z.";

    if ( !( $line && $line =~ /^\d+$/xms && $priority ) ) {
        die "$error\n";
    }
    elsif ( $priority !~ /^[[:upper:]]|[[:lower:]]$/xms ) {
        die "$error\n";
    }
    $priority = uc $priority;
    my $prefix = $self->_get_prefix;

    my $entry = $self->todo->list->[ $line - 1 ];
    die "$prefix: No task $line.\n" unless defined $entry;

    my $old_priority = $entry->priority;
    if ( defined $old_priority && $old_priority eq $priority ) {
	return $self->log->(
	    "$line ", $entry->text,
	    "\n$prefix: $line already prioritized ($priority).\n" );
    }
    
    if ( $entry->pri($priority) && $self->todo->save ) {
	my $priority = $entry->priority;
	my $message = "$line " . $entry->text . "\n$prefix: $line ";
	$message .= $old_priority
	    ? "re-prioritized from ($old_priority) to ($priority).\n"
	    : "prioritized ($priority).\n";
	    
        return $self->log->( $message );
    }
    die "Unable to prioritize entry\n";
}

sub shorthelp {
    Text::Todo::Help::usage(1);
}

## no critic 'sigal'
sub replace { return &unsupported }
sub report  { return &unsupported }
## use critic

sub _number_list {
    my ( $iter, @list ) = @_;

    my $next = 0;
    $iter //= sub { ++$next };

    return grep { $_->{entry}->text !~ /^\s*$/ }
    map { { line => $iter->(), entry => $_ } } @list;
} 

sub _show_sorted_list {
    my ( $self, $terms, @list ) = @_;

    $terms //= [];
    my ( $shown, $lz ) = ( 0, 1 );

    {
    	use integer;
	my @numbers = map { $_->{line} } @list;

	use List::Util qw(max);
	my $ln = max( @numbers );
	$ln //= 0;
    	++$lz while ( $ln /= 10 );
    }

    my @sorted = map { sprintf "%0${lz}d %s", $_->{line}, $_->{entry}->text }
        sort { uc $a->{entry}->text cmp uc $b->{entry}->text } @list;

    use Text::Todo::Filter;
    my $filter = Text::Todo::Filter::make_filter( $self->config );

    @sorted = _match( $terms, \@sorted ) if @$terms;

    foreach my $line ( @sorted ) {
	$self->log->( $filter->( $line ) . "\n" );

	$shown++;
    }

    return $shown;
}

sub _match {
    my ( $terms, $list ) = @_;
    
    my @exclusive = grep { /^-/ } @$terms;
    map { s/^-// } @exclusive;
    @exclusive = map { qr/$_/i } map { quotemeta } @exclusive;

    my @inclusive = map { qr/$_/i } map { quotemeta } grep { !/^-/ } @$terms;

    my $exclude = sub {
	my ( $line ) = @_;

	for ( @exclusive ) {
	    return 0 if $line =~ /$_/;
	}
	return 1;
    };
    my @filtered = grep { $exclude->( $_ ) } @$list;

    my $include = sub {
	my ( $line ) = @_;

	for ( @inclusive ) {
	    return 0 if $line !~ /$_/;
	}
	return 1;
    };
    @filtered = grep { $include->( $_ ) } @filtered;

    return wantarray ? @filtered : \@filtered;
}

sub _match_tag_type {
    my ($self, $tag_type, @terms) = @_;

    my @list = map { $_->text } $self->todo->list;

    my @matched = _match( \@terms, \@list );
    use Text::Todo::Entry;
    my @entries = map { Text::Todo::Entry->new( $_ ) } @matched;
    
    my %available;
    my $tag_accessor = "${tag_type}s";
    foreach my $e ( @entries ) {
	foreach my $t ( $e->$tag_accessor ) {
	    $available{$t} = 1;
	}
    }

    my @tags = sort keys %available;
    return wantarray ? @tags : \@tags;
}

sub _show_list_footer {
    my $self = shift;
    my %parameters = @_;
    $parameters{file} //= $self->todo->file( 'todo_file' );

    $parameters{shown} ||= 0;
    $parameters{total} ||= 0;
    $parameters{with_separator} //= 1; #print separator by default

    $self->log->( "--\n" ) if $parameters{with_separator};

    my $file = $self->_get_prefix( $parameters{file} );
    $self->log->(
	"$file: $parameters{shown} of $parameters{total} tasks shown\n" );

    return 1;
}

sub unsupported { die "Unsupported action\n" }

1;
__END__

=encoding utf8

=head1 NAME

Text::Todo::Client - a todo.sh implementation in perl

=head1 SYNOPSIS

    use Text::Todo::Client;

    my $client = Text::Todo::Client->new( config => $config );

    if ( $client->can( $action ) ) {
	$client->$action( @args );
    }

=head1 DESCRIPTION

Client.pm implements all builtin actions found in todo.sh



    
