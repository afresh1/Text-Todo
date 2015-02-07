Text::Todo - Perl interface to todotxt files
============================================

This module is a basic interface to the todo.txt files as described by
Lifehacker and extended by members of their community.

For more information see http://todotxt.com

This module supports the 3 axes of an effective todo list.
Priority, Project and Context.

It does not support other notations or many of the more advanced features of
the todo.sh like plugins.

It should be extensible, hopefully will be before a 1.0 release.

Sadly I have not been using this module much myself so development is slow.
I am happy to review patches however.

TODO
====

Finish the "dudelicious.pl" [Mojolicious](http://mojolicio.us)
Todo::Text frontend.

Add support for extensible plugins.

Move more parts from todo.pl into modules to make it easy to add tests.

And of course, more tests.

Clean up "uninitialized value" warnings in output when run without a config file.

General improvements are super welcome, such as making perlcritic.t pass.
