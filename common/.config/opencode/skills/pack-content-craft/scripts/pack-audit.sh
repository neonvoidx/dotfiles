#!/usr/bin/env bash
# pack-audit.sh — Structural audit of a pack source tree
# Usage: pack-audit.sh <pack-root>
#
# Outputs a per-file table: path, line count, budget compliance,
# frontmatter field presence, and notes (CSO trigger check for skills).
# Designed to be run as the first step of a pack review.
set -euo pipefail

root="${1:?Usage: pack-audit.sh <pack-root>}"
root="${root%/}"

printf "%-50s %5s %7s %4s %s\n" "FILE" "LINES" "BUDGET" "FM" "NOTES"
printf "%-50s %5s %7s %4s %s\n" "----" "-----" "------" "--" "-----"

find "$root" \( -path "*/rules/*.md" -o -path "*/skills/*.md" -o -path "*/workflows/*.md" -o -path "*/agents/*.md" \) -type f | sort | while IFS= read -r f; do
    rel="${f#$root/}"
    lines=$(wc -l < "$f")

    # Frontmatter boundary (second --- line)
    fm_end=$(awk '/^---$/{n++; if(n==2){print NR; exit}}' "$f")

    # Frontmatter is required on rules, workflows, agents, and SKILL.md entry points.
    # Supporting files within skill directories (references/, scripts/, facets) are exempt.
    notes=""
    fm=""
    needs_fm=false
    case "$rel" in
        rules/*|workflows/*|agents/*|skills/*/SKILL.md) needs_fm=true ;;
    esac

    if $needs_fm; then
        if [[ -n "$fm_end" ]]; then
            fm=$(head -n "$fm_end" "$f")
            missing=""
            echo "$fm" | grep -q '^name:'          || missing="${missing}name "
            echo "$fm" | grep -q '^description:'   || missing="${missing}desc "
            echo "$fm" | grep -q 'owner:'          || missing="${missing}owner "
            echo "$fm" | grep -q 'last_updated:'   || missing="${missing}updated "
            fm_ok=$([[ -z "$missing" ]] && echo "ok" || echo "MISS")
            [[ -n "$missing" ]] && notes="missing: ${missing% }"
        else
            fm_ok="NONE"
            notes="no frontmatter"
        fi
    else
        fm_ok="-"
        [[ -n "$fm_end" ]] && fm=$(head -n "$fm_end" "$f")
    fi

    # Budget check (rules: 60, SKILL.md: 500)
    budget="-"
    case "$rel" in
        rules/*)           [[ $lines -le 60 ]]  && budget="ok" || budget="OVER" ;;
        skills/*/SKILL.md) [[ $lines -le 500 ]] && budget="ok" || budget="OVER" ;;
    esac

    # CSO check for skill descriptions
    if [[ "$rel" == skills/*/SKILL.md && -n "$fm" ]]; then
        desc=$(echo "$fm" | grep '^description:' | head -1)
        if ! echo "$desc" | grep -qi 'use when'; then
            notes="${notes:+$notes; }CSO: missing trigger"
        fi
    fi

    printf "%-50s %5d %7s %4s %s\n" "$rel" "$lines" "$budget" "$fm_ok" "$notes"
done
