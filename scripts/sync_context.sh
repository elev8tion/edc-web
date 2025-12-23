#!/usr/bin/env bash
set -euo pipefail

if ! command -v git >/dev/null 2>&1; then
  echo "git is required to generate the context snapshot." >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root"

echo "=============================================="
echo " Everyday Christian — Context Snapshot"
echo " Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo " Root: $repo_root"
echo "=============================================="

current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'DETACHED')"
echo
echo "Branch: $current_branch"
echo "Last commit: $(git log -1 --pretty='%h %ad — %s' --date=short 2>/dev/null || echo 'N/A')"

echo
echo "Uncommitted changes:"
git status --short

echo
echo "Recent commits:"
git log -5 --pretty='  * %h %ad — %s' --date=short

echo
echo "Key directories:"
printf '  * %s\n' lib test assets scripts status docs android ios

echo
echo "Top-level lib modules:"
find lib -maxdepth 2 -type d -print | sed 's#^\./##' | sort

echo
echo "Open TODO / FIXME markers:"
if command -v rg >/dev/null 2>&1; then
  rg --no-heading --line-number --colors 'match:fg:yellow' --colors 'line:fg:cyan' 'TODO|FIXME' lib test || true
else
  grep -RinE 'TODO|FIXME' lib test || true
fi

echo
echo "Status artifacts:"
if [ -d status ]; then
  ls -1 status
fi

echo
echo "Docs updated recently:"
git log -5 --name-only --pretty='--- %h %ad' -- docs | sed 's#^#  #'

echo
echo "Done. Share this output when asking external collaborators for assistance."
