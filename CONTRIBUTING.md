hey! Thanks for considering contributing. I'm happy to receive any issues you
have, or even better any PRs for features you may want.

For issues please try to describe as comprehensively as you can what you were
doing / what you want to do so I can reproduce the bug or design in the feature
you want. Even better if you could add in code snippets, and for bugs you're
raising due to unexpected errors, please include the full error message and all
backtrace :-)

Some guidelines for PRs:

Please use RuboCop. It doesn't have to be perfect, but do try to match the
general style I've got going on.

Tests are mandatory for any new stuff! Please fix any tests you break. If you
break any tests inside a `describe "internals"` block, just change it to an
`xdescribe` block.

IMO the ResponseParser is only in charge of splitting the command, success &
data sections of a response. If you're adding additional parsing (e.g. parsing a
`LIST <remote>` response to get remote names) - that parser should be separate
and called manually on the `Response`. I'm happy for `Response` to grow a
`#parse` method which chooses the parser based on the command though :)

Have fun!
