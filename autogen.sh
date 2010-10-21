#! /bin/sh
# JMJ
# autogen.sh: get the build management up from scratch
# See the file COPYING for copying conditions

# I used the following package versions:

#  autoconf	2.13
#  automake	1.4

set -v
aclocal && autoheader && automake && autoconf && ./configure "$@"
