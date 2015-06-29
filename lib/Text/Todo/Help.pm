use strict;
use warnings;

package Text::Todo::Help;

my $oneline_usage =<<'ONELINE_USAGE';
todo.pl [-fhpantvV] [-d todo_config] action [task_number] [task_description]
ONELINE_USAGE

my $builtin_actions_help=<<'ACTIONS_HELP';
  Built-in Actions:
    add "THING I NEED TO DO +project @context"
    a "THING I NEED TO DO +project @context"
      Adds THING I NEED TO DO to your todo.txt file on its own line.
      Project and context notation optional.
      Quotes optional.

    addm "FIRST THING I NEED TO DO +project1 @context
    SECOND THING I NEED TO DO +project2 @context"
      Adds FIRST THING I NEED TO DO to your todo.txt on its own line and
      Adds SECOND THING I NEED TO DO to you todo.txt on its own line.
      Project and context notation optional.

    addto DEST "TEXT TO ADD"
      Adds a line of text to any file located in the todo.txt directory.
      For example, addto inbox.txt "decide about vacation"

    append ITEM# "TEXT TO APPEND"
    app ITEM# "TEXT TO APPEND"
      Adds TEXT TO APPEND to the end of the task on line ITEM#.
      Quotes optional.

    archive
      Moves all done tasks from todo.txt to done.txt and removes blank lines.

    command [ACTIONS]
      Runs the remaining arguments using only todo.sh builtins.
      Will not call any .todo.actions.d scripts.

    deduplicate
      Removes duplicate lines from todo.txt.

    del ITEM# [TERM]
    rm ITEM# [TERM]
      Deletes the task on line ITEM# in todo.txt.
      If TERM specified, deletes only TERM from the task.

    depri ITEM#[, ITEM#, ITEM#, ...]
    dp ITEM#[, ITEM#, ITEM#, ...]
      Deprioritizes (removes the priority) from the task(s)
      on line ITEM# in todo.txt.

    do ITEM#[, ITEM#, ITEM#, ...]
      Marks task(s) on line ITEM# as done in todo.txt.

    help [ACTION...]
      Display help about usage, options, built-in and add-on actions,
      or just the usage help for the passed ACTION(s).

    list [TERM...]
    ls [TERM...]
      Displays all tasks that contain TERM(s) sorted by priority with line
      numbers.  Each task must match all TERM(s) (logical AND); to display
      tasks that contain any TERM (logical OR), use
      "TERM1\|TERM2\|..." (with quotes), or TERM1\\\|TERM2 (unquoted).
      Hides all tasks that contain TERM(s) preceded by a
      minus sign (i.e. -TERM). If no TERM specified, lists entire todo.txt.

    listall [TERM...]
    lsa [TERM...]
      Displays all the lines in todo.txt AND done.txt that contain TERM(s)
      sorted by priority with line  numbers.  Hides all tasks that
      contain TERM(s) preceded by a minus sign (i.e. -TERM).  If no
      TERM specified, lists entire todo.txt AND done.txt
      concatenated and sorted.

    listaddons
      Lists all added and overridden actions in the actions directory.

    listcon [TERM...]
    lsc [TERM...]
      Lists all the task contexts that start with the @ sign in todo.txt.
      If TERM specified, considers only tasks that contain TERM(s).

    listfile [SRC [TERM...]]
    lf [SRC [TERM...]]
      Displays all the lines in SRC file located in the todo.txt directory,
      sorted by priority with line  numbers.  If TERM specified, lists
      all lines that contain TERM(s) in SRC file.  Hides all tasks that
      contain TERM(s) preceded by a minus sign (i.e. -TERM).  
      Without any arguments, the names of all text files in the todo.txt
      directory are listed.

    listpri [PRIORITIES] [TERM...]
    lsp [PRIORITIES] [TERM...]
      Displays all tasks prioritized PRIORITIES.
      PRIORITIES can be a single one (A) or a range (A-C).
      If no PRIORITIES specified, lists all prioritized tasks.
      If TERM specified, lists only prioritized tasks that contain TERM(s).
      Hides all tasks that contain TERM(s) preceded by a minus sign
      (i.e. -TERM).  

    listproj [TERM...]
    lsprj [TERM...]
      Lists all the projects (terms that start with a + sign) in
      todo.txt.
      If TERM specified, considers only tasks that contain TERM(s).

    move ITEM# DEST [SRC]
    mv ITEM# DEST [SRC]
      Moves a line from source text file (SRC) to destination text file (DEST).
      Both source and destination file must be located in the directory defined
      in the configuration directory.  When SRC is not defined
      it is by default todo.txt.

    prepend ITEM# "TEXT TO PREPEND"
    prep ITEM# "TEXT TO PREPEND"
      Adds TEXT TO PREPEND to the beginning of the task on line ITEM#.
      Quotes optional.

    pri ITEM# PRIORITY
    p ITEM# PRIORITY
      Adds PRIORITY to task on line ITEM#.  If the task is already
      prioritized, replaces current priority with new PRIORITY.
      PRIORITY must be a letter between A and Z.

    replace ITEM# "UPDATED TODO"
      Replaces task on line ITEM# with UPDATED TODO.

    report
      Adds the number of open tasks and done tasks to report.txt.

    shorthelp
      List the one-line usage of all built-in and add-on actions.

ACTIONS_HELP


sub action_help {
    my ( $action ) = @_;

    if ( $action ) {
	$builtin_actions_help =~ /^(    $action.+?^$)/sm;
	my $help = $1;
	return $help ? \$help : undef;
    } else {
	return \$builtin_actions_help;
    }
}

sub options_help {
    print "  Usage: $oneline_usage";
    print <<'END_OPTIONS_HELP';

  Options:
    -@
        Hide context names in list output.  Use twice to show context
        names (default).
    -+
        Hide project names in list output.  Use twice to show project
        names (default).
    -c
        Color mode
    -d CONFIG_FILE
        Use a configuration file other than the default ~/.todo/config
    -f
        Forces actions without confirmation or interactive input
    -h
        Display a short help message; same as action "shorthelp"
    -p
        Plain mode turns off colors
    -P
        Hide priority labels in list output.  Use twice to show
        priority labels (default).
    -a
        Don't auto-archive tasks automatically on completion
    -A
        Auto-archive tasks automatically on completion
    -n
        Don't preserve line numbers; automatically remove blank lines
        on task deletion
    -N
        Preserve line numbers
    -t
        Prepend the current date to a task automatically
        when it's added.
    -T
        Do not prepend the current date to a task automatically
        when it's added.
    -v
        Verbose mode turns on confirmation messages
    -vv
        Extra verbose mode prints some debugging information and
        additional help text
    -V
        Displays version, license and credits
    -x
        Disables TODOTXT_FINAL_FILTER


END_OPTIONS_HELP
}
    
sub usage {
    my ($long) = @_;

    print "  Usage: $oneline_usage";

    if ($long) {
        print <<'EOL';

  Actions:
    add|a "THING I NEED TO DO +project @context"
    addto DEST "TEXT TO ADD"
    append|app NUMBER "TEXT TO APPEND"
    archive
    command [ACTIONS]
    del|rm NUMBER [TERM]
    dp|depri NUMBER
    do NUMBER
    help
    list|ls [TERM...]
    listaddons
    listall|lsa [TERM...]
    listcon|lsc
    listfile|lf SRC [TERM...]
    listpri|lsp [PRIORITY]
    listproj|lsprj
    move|mv NUMBER DEST [SRC]
    prepend|prep NUMBER "TEXT TO PREPEND"
    pri|p NUMBER PRIORITY
    replace NUMBER "UPDATED TODO"
    report
    shorthelp

  Actions can be added and overridden using scripts in the actions directory.
  Run 'todo.pl help' for more details including available addons.
EOL
    }
    else {
        print <<'EOL';
Try 'todo.pl -h' for more information.
EOL
    }

    exit;
}

1;
__END__

=encoding utf8

=head1 NAME

Text::Todo::Help - Help messages and utility functions

=head1 SYNOPSIS

    use Text::Todo::Help;

    Text::Todo::Help::action_help();
    Text::Todo::Help::action_help( $action_name );
    Text::Todo::Help::options_help();

=head1 DESCRIPTION

Help.pm groups functions that provide help messages.

=head1 FUNCTIONS

=head2 options_help

    Text::Todo::Help::options_help();

Prints the various command line options a todo.pl client accepts.

=head2 action_help

    Text::Todo::Help::action_help();
    Text::Todo::Help::action_help( $action_name );

Prints a builtin action's help if given an argument. Prints help for all 
builtins otherwise.

=head2 usage

    Text::Todo::Help::usage( $list_builtins );

Prints a short usage message. Lists builtin actions if $list_builtins is true.

