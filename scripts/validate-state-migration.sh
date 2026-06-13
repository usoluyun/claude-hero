#!/usr/bin/env bash
#
# validate-state-migration.sh
#
# Verify that `.omo/state/` was properly migrated from `docs/`.
# Prints PASS/FAIL for each check. Exit 0 if all pass, exit 1 if any fail.
#
# Usage: bash scripts/validate-state-migration.sh

set -u
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ALL_PASS=true

check() {
    local label="$1"
    shift
    if "$@"; then
        echo "  PASS  ${label}"
    else
        echo "  FAIL  ${label}"
        ALL_PASS=false
    fi
}

echo "=== State Migration Validation ==="
echo ""

# 1. .omo/state/ directory exists
check ".omo/state/ directory exists" test -d "${ROOT_DIR}/.omo/state"

# 2. All 4 state files exist
for f in refresh-state.json workflow-registry.json agent-executions.json session-history.json; do
    check ".omo/state/${f} exists" test -f "${ROOT_DIR}/.omo/state/${f}"
done

# 3. .omo/state/.cache/.gitignore exists and contains "*.*"
CACHE_GITIGNORE="${ROOT_DIR}/.omo/state/.cache/.gitignore"
check ".omo/state/.cache/.gitignore exists" test -f "${CACHE_GITIGNORE}"
if [ -f "${CACHE_GITIGNORE}" ]; then
    check ".omo/state/.cache/.gitignore contains '*.*'" grep -qF '*.*' "${CACHE_GITIGNORE}"
fi

# 4. Root .gitignore contains .omo/state/.cache/
ROOT_GITIGNORE="${ROOT_DIR}/.gitignore"
check ".gitignore contains .omo/state/.cache/" test -f "${ROOT_GITIGNORE}" && grep -qF '.omo/state/.cache/' "${ROOT_GITIGNORE}"

# 5. manifest.yaml contains .omo/state entry with install: false
MANIFEST="${ROOT_DIR}/manifest.yaml"
check "manifest.yaml contains .omo/state with install: false" \
    test -f "${MANIFEST}" && \
    grep -qF 'source: .omo/state' "${MANIFEST}" && \
    grep -qF 'install: false' "${MANIFEST}"

echo ""
echo "=== Summary ==="
if [ "${ALL_PASS}" = true ]; then
    echo "  All checks PASSED. Migration is valid."
    exit 0
else
    echo "  Some checks FAILED. Migration is incomplete."
    exit 1
fi
