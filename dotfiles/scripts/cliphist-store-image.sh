#!/usr/bin/env bash
# wl-paste --watch feeds the clipboard image on stdin — recompress before
# handing to cliphist store, since cliphist (0.7.0) silently drops (exit 0,
# never persisted, no error) any image payload above ~5MB, and a full-res
# screenshot routinely exceeds that regardless of how it was captured
# (niri's built-in screenshot action, grim, a browser, etc.). Recompressing
# here, at the single point every clipboard image funnels through, fixes it
# for every source at once instead of only ones whose capture command we
# control.

TMP=$(mktemp)
trap 'rm -f "$TMP" "$TMP.out"' EXIT
cat > "$TMP"

magick "$TMP" -strip -define png:compression-level=9 "png:$TMP.out"

# Max PNG compression alone isn't always enough for high-entropy content
# (a busy/detailed screen can still land near the threshold even at level
# 9) — fall back to lossy JPEG, which reliably lands well under it, rather
# than silently losing the clipboard entry to cliphist's size cap.
if [ "$(stat -c%s "$TMP.out")" -gt 4000000 ]; then
    magick "$TMP" -strip -quality 85 "jpg:$TMP.out"
fi

cliphist store < "$TMP.out"
