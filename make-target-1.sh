#!/bin/sh
set -em

# This is a script to be run as part of make.sh. The only time you'd
# want to run it by itself is if you're trying to cross-compile the
# system or if you're doing some kind of troubleshooting.

# This software is part of the SBCL system. See the README file for
# more information.
#
# This software is derived from the CMU CL system, which was
# written at Carnegie Mellon University and released into the
# public domain. The software is in the public domain and is
# provided with absolutely no warranty. See the COPYING and CREDITS
# files for more information.

echo //entering make-target-1.sh

LANG=C
LC_ALL=C
export LANG LC_ALL

# Load our build configuration
. output/build-config

if [ -n "$SBCL_HOST_LOCATION" ]; then
    echo //copying host-1 output files to target
    rsync -a "$SBCL_HOST_LOCATION/output/" output/
    rsync -a "$SBCL_HOST_LOCATION/src/runtime/genesis" src/runtime
fi

# Build the runtime system
#
# (This C build has to come after the first genesis in order to get
# 'sbcl.h' which the C build. It could come either before or after running
# the cross compiler; that doesn't matter.)
echo //building runtime system and symbol table file

$GNUMAKE -C src/runtime clean
$GNUMAKE $SBCL_MAKE_JOBS -C src/runtime all

# Use a little C program to grab stuff from the C header files and
# smash it into Lisp source code.
# -C tools-for-build is broken on some gnu make versions.
if $android
then
    ( cd tools-for-build; $CC -I../src/runtime -ldl -o grovel-headers grovel-headers.c)
    . ./tools-for-build/android_run.sh
    android_run tools-for-build/grovel-headers > output/stuff-groveled-from-headers.lisp
else
    ( cd tools-for-build; $GNUMAKE -I../src/runtime grovel-headers )
    tools-for-build/grovel-headers > output/stuff-groveled-from-headers.lisp
fi
touch -r tools-for-build/grovel-headers.c output/stuff-groveled-from-headers.lisp

if [ -n "$SBCL_HOST_LOCATION" ]; then
    echo //copying target-1 output files to host
    rsync -a output/stuff-groveled-from-headers.lisp "$SBCL_HOST_LOCATION/output"
fi
