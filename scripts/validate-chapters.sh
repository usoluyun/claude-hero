#!/bin/bash
# Validate that all agents/hero-java-*.md files contain the 5 required chapters.
# Usage: ./scripts/validate-chapters.sh

CHAPTERS=("## Role" "## Success Criteria" "## Constraints" "## Failure Modes" "## Final Checklist")
FAIL=0

for f in agents/hero-java-*.md; do
  [ -f "$f" ] || continue
  OK=1
  for ch in "${CHAPTERS[@]}"; do
    grep -qF "$ch" "$f" || { OK=0; break; }
  done
  if [ "$OK" -eq 1 ]; then
    echo "PASS: $f"
  else
    echo "FAIL: $f"
    FAIL=1
  fi
done

exit $FAIL
