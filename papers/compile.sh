#! /bin/bash

CMD="compile"
DIR=""

for arg in "$@"; do
    if [ "$arg" = "--watch" ]; then
        CMD="watch"
    elif [ -z "$DIR" ]; then
        DIR="$arg"
    else
        echo "Usage: $0 [--watch] <directory>" >&2
        exit 1
    fi
done

if [ -z "$DIR" ]; then
    echo "Usage: $0 [--watch] <directory>" >&2
    exit 1
fi

cd "$DIR" || exit 1

typst "$CMD" main.typ \
    --root .. \
    --format bundle \
    --features bundle \
    --features html \
    "../../content/publications/$DIR/"