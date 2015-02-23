use strict;
use warnings;

package Text::Todo::Filter;

my $config;

my $highlight = sub {
    return '' if $config->{ lc 'TODOTXT_PLAIN' };
    my $color = $config->{lc $_[0]};
    return '' unless $color;
    $color =~ s/'\\+033(\[(?:\d+;)*\d+m)'/\033$1/;
    return $color;
};

sub make_filter {
    $config = shift;

    my $clr;
    my $prj_beg = $highlight->( 'COLOR_PROJECT' );
    my $prj_end = $prj_beg ? $highlight->( 'DEFAULT' ) : '';
    my $ctx_beg = $highlight->( 'COLOR_CONTEXT' );
    my $ctx_end = $ctx_beg ? $highlight->( 'DEFAULT' ) : '';

    my $ctx_repl = $config->{ lc 'HIDE_CONTEXT' }
    ? sub { '' } : sub { "$1$ctx_beg$2$ctx_end$clr" };

    my $prj_repl = $config->{ lc 'HIDE_PROJECT' }
    ? sub { '' } : sub { "$1$prj_beg$2$prj_end$clr" };

    return sub {
	my $line = shift;

	$clr = '';
	if ( $line =~ /^\d+ x / ) {
	    $clr = $highlight->( 'COLOR_DONE' );
	} elsif ( $line =~ /^[0-9]+ \(([A-Z])\) / ) {
	    $clr = $highlight->( "PRI_$1" );
	    $clr ||= $highlight->( 'PRI_X' );
	    $line =~ s/( \([A-Z]\))// if $config->{ lc 'HIDE_PRIORITY' };
	}
	my $end_clr = $clr ? $highlight->( 'DEFAULT' ) : '';

	$line =~ s/(\s)(@(?:[^\s]*\w))(?=\s|$)/$ctx_repl->()/eg
	    if $ctx_beg || $config->{ lc 'HIDE_CONTEXT' };
	$line =~ s/(\s)([+](?:[^\s]*\w))(?=\s|$)/$prj_repl->()/eg
	    if $prj_beg || $config->{ lc 'HIDE_PROJECT' };

	return "$clr$line$end_clr";
    }
}

1;


