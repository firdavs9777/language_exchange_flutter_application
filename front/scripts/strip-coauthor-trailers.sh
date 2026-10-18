#!/usr/bin/env bash
# Strip "Co-Authored-By: Claude ..." trailers from the whole history of main in
# both BananaTalk repos and force-push. Works in throwaway clones so your
# working checkouts (and any agents editing them) are untouched. A backup of
# the pre-rewrite main is pushed to backup/main-with-trailers-<date> first.
#
# Run from anywhere:  bash scripts/strip-coauthor-trailers.sh
set -euo pipefail

STAMP=$(date +%Y-%m-%d)
WORK=$(mktemp -d /tmp/strip-trailers.XXXXXX)
trap 'rm -rf "$WORK"' EXIT

rewrite() {
  local name=$1 local_path=$2 remote_url=$3
  echo "== $name"
  git clone -q "$local_path" "$WORK/$name"
  cd "$WORK/$name"
  git remote set-url origin "$remote_url"
  git fetch -q origin
  git checkout -q -B main origin/main
  echo "   trailers before: $(git log --format=%B | grep -c 'Co-Authored-By' || true)"
  git push -q origin "main:refs/heads/backup/main-with-trailers-$STAMP"
  FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --msg-filter \
    "sed -e '/^Co-Authored-By: Claude/d' | sed -e :a -e '/^\n*\$/{\$d;N;ba' -e '}'" \
    main >/dev/null 2>&1
  echo "   trailers after:  $(git log --format=%B | grep -c 'Co-Authored-By' || true)"
  git push --force origin main
  echo "   origin/main is now $(git ls-remote origin main | cut -c1-7)"
  cd - >/dev/null
}

rewrite web \
  /Users/davis/Desktop/Personal/language_exchange_web_front \
  https://github.com/firdavs9777/language_exchange_web_front.git

rewrite backend \
  /Users/davis/Desktop/Personal/language_exchange_backend_application \
  git@github.com:firdavs9777/language_exchange_backend_application.git

cat <<'EOF'

Done. Next, in each local checkout once its working tree is clean:
  git fetch origin && git checkout main && git reset --hard origin/main
Branches created before the rewrite must be rebased onto the new main
(their commits still carry the old trailer text in their own history).
EOF
