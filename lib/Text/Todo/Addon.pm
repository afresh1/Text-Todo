use strict;
use warnings;
use Carp;

package Text::Todo::Addon;

my $get_addon_dir = sub {
    my $config = shift;
    my $ad = $config->{ lc 'TODO_ACTIONS_DIR' };
    return $ad if defined $ad && -d $ad;
    $ad = "$ENV{HOME}/.todo/actions";
    return $ad if -d $ad;
    $ad = "$ENV{HOME}/.todo.actions.d";
    return $ad if -d $ad;

    #empty string means no directory exists
    return '';
};

my $make_addon = sub {
    my ( $ad, $action ) = @_;

    if ( -d "$ad/$action" && -f -x "$ad/$action/$action" ) {
	return sub { system( "$ad/$action/$action", @_ ); };
    } elsif ( -d $ad && -f -x "$ad/$action" ) {
	return sub { system( "$ad/$action", @_ ); };
    }
    return undef;
};

sub for_name {
    my ( $config, $action ) = @_;

    my $ad = $get_addon_dir->( $config );
    return undef unless $ad;

    return $make_addon->( $ad, $action );
}

sub get_all {
    my ( $config, $all_addons ) = @_;

    my $ad = $get_addon_dir->( $config );

    if ( $ad ) {
	opendir( my $dh, $ad ) or croak( "Unable to opendir [$ad]: $!" );
	while ( my $action = readdir( $dh ) ) {
	    if ( my $addon = for_name( $config, $action ) ) {
		$all_addons->{ $action } =  $addon ;
	    }
	}
	closedir $dh;
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Text::Todo::Addon - addon discovery and processing functions

=head1 SYNOPSIS

    use Text::Todo::Addon;

    my $addon = Text::Todo::Addon::for_name( 'addon_name' );

    $addon->( @args );

=head1 DESCRIPTION

Addon.pm groups functions used for handling addons.

=head1 FUNCTIONS

=head2 for_name

    my $addon = Text::Todo::Addon::for_name( $config, 'addon_name' );

Checks if an addon with the specified name exists. Returns a function that 
represents it if it exists or undef otherwise.

=head2 get_all

    Text::Todo::Addon::get_all( $config, $addons_ref )

Fill a hashref with all installed addons. Hash's keys are addon names.

    
