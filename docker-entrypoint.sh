#!/bin/bash
set -ex

# if command starts with an option, prepend zend
if [ "${1:0:1}" = '-' ]; then
    set -- /usr/local/bin/zend "$@"
fi

exec "$@"
