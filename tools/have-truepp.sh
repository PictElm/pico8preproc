#!/bin/sh -e
# Example: tools/have-truepp.sh 0.0.5
log() { echo "$@" >&2; }
die() { log "$@"; exit 1; }

cd "${0%/*}/../.cache"
ver=$1

test -z "$ver" && die 'No version code specified'

at=$PWD/truepps/$ver
test -f "$at/truepp" || ../tools/make-truepp.sh $ver "$at/truepp"

test -x "$at/truepp" || die "Found item does not contain the binary executable at: '$at/truepp'"
echo "$at/truepp"
