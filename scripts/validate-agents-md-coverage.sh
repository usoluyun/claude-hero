#!/bin/bash
# validate-agents-md-coverage.sh
# Verifies that every hero-java-*.md file in agents/ has a matching entry
# in agents/AGENTS.md YAML frontmatter.
# Exit 0 if all covered, exit 1 if any missing.

set -u

AGENTS_MD="agents/AGENTS.md"

if [ ! -f "$AGENTS_MD" ]; then
  echo "ERROR: $AGENTS_MD not found"
  exit 1
fi

# Extract agent names from AGENTS.md YAML frontmatter (name: fields between ---)
REGISTERED=$(sed -n '/^---$/,/^---$/p' "$AGENTS_MD" | grep '\- name:' | sed 's/.*name: *//')

# List actual agent files (strip path and .md suffix)
FILES=$(ls agents/hero-java-*.md | sed 's|agents/||;s|\.md||')

FAIL=0
MISSING_LIST=""

for agent in $FILES; do
  if echo "$REGISTERED" | grep -qF "$agent"; then
    echo "  COVERED: $agent"
  else
    echo "  MISSING:  $agent"
    MISSING_LIST="$MISSING_LIST $agent"
    FAIL=1
  fi
done

echo ""
REG_COUNT=$(echo "$REGISTERED" | wc -l | tr -d ' ')
FILE_COUNT=$(echo "$FILES" | wc -l | tr -d ' ')
echo "AGENTS.md entries: $REG_COUNT"
echo "Agent files:      $FILE_COUNT"

if [ $FAIL -eq 0 ]; then
  echo ""
  echo "✓ All $FILE_COUNT hero-java agents are covered in AGENTS.md"
else
  echo ""
  echo "✗ Missing entries in AGENTS.md:$MISSING_LIST"
fi

exit $FAIL
