#!/usr/bin/env bash
# Parses rofimoji's bundled emoji CSVs into a single cached JSON array for
# the Quickshell emoji picker (see EmojiPickerState.qml). Self-skips unless
# rofimoji's resolved store path has changed since the last run, so calling
# this on every panel-open (see EmojiPickerWindow.qml) stays cheap.

OUT_DIR="$HOME/.cache/emoji"
OUT_FILE="$OUT_DIR/emoji.json"
STAMP_FILE="$OUT_DIR/.rofimoji-store"
mkdir -p "$OUT_DIR"

ROFIMOJI_BIN=$(command -v rofimoji) || { echo "rofimoji not found in PATH" >&2; exit 1; }
ROFIMOJI_STORE=$(readlink -f "$ROFIMOJI_BIN")

if [ -f "$OUT_FILE" ] && [ -f "$STAMP_FILE" ] && [ "$(cat "$STAMP_FILE")" = "$ROFIMOJI_STORE" ]; then
    exit 0
fi

# Walk from the package root rather than assuming a lib/pythonX.Y/... literal
# — that segment drifts on a python version bump in the derivation.
PKG_ROOT="${ROFIMOJI_STORE%/bin/rofimoji}"
DATA_DIR=$(find "$PKG_ROOT" -maxdepth 6 -type d -name data -path "*/picker/*" | head -1)

if [ -z "$DATA_DIR" ]; then
    echo "could not locate rofimoji emoji data dir under $PKG_ROOT" >&2
    exit 1
fi

# Format: "<emoji> <name>[ <small>(<kw1, kw2, ...>)</small>]" — the keyword
# block is optional (most flag/skin-tone-variant entries omit it), so it's
# located by the literal marker strings rather than assumed present. No
# quotes/backslashes appear anywhere in the source data, so plain string
# interpolation into JSON is safe without an escaping pass.
awk '
    BEGIN { print "[" ; first = 1 }
    {
        sp = index($0, " ")
        if (sp == 0) next
        emoji = substr($0, 1, sp - 1)
        rest = substr($0, sp + 1)

        marker = index(rest, " <small>(")
        if (marker > 0) {
            name = substr(rest, 1, marker - 1)
            kwstart = marker + 9
            kwend = index(rest, ")</small>")
            kwraw = substr(rest, kwstart, kwend - kwstart)
            n = split(kwraw, kws, ", ")
        } else {
            name = rest
            n = 0
        }

        if (!first) printf ",\n"
        first = 0
        printf "{\"char\":\"%s\",\"name\":\"%s\",\"keywords\":[", emoji, name
        for (i = 1; i <= n; i++) {
            if (i > 1) printf ","
            printf "\"%s\"", kws[i]
        }
        printf "]}"
    }
    END { print "\n]" }
' "$DATA_DIR"/emojis_*.csv > "$OUT_FILE"

echo "$ROFIMOJI_STORE" > "$STAMP_FILE"
