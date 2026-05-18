#!/bin/bash
# @ AI Context: Thin shim. The real entry point is setup.sh (interactive
# wizard). Kept here for backwards compatibility with old muscle memory / docs.
exec "$(dirname "$0")/setup.sh" "$@"
