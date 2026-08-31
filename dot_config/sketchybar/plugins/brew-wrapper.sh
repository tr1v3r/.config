#!/bin/bash
# Run brew from inside a sketchybar plugin process.
#
# sketchybar's children inherit SIGCHLD=SIG_IGN; POSIX then auto-reaps
# grandchildren and waitpid returns no status, so Homebrew's Ruby (which
# forks via IO.popen("-") and reads $CHILD_STATUS) dies with
# "undefined method 'success?' for nil". Resetting the disposition to
# DEFAULT and exec'ing brew fixes it (the reset survives exec).
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
RUBY=/opt/homebrew/Library/Homebrew/vendor/portable-ruby/current/bin/ruby
exec "$RUBY" -e 'Signal.trap("CHLD", "DEFAULT"); exec "/opt/homebrew/bin/brew", *ARGV' "$@"
