#!/usr/bin/env bash

set -euo pipefail
PATH=/net/slurm/releases/production.el8.x86_64/bin:/usr/local/bin:/usr/bin:/bin
umask 0002

# ============================================================
# Defaults
# ============================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

OUTPUT_PATH="$SCRIPT_DIR"
GRANT=""
# GRANT=$(sacctmgr -nP show assoc where user="$USER" format=Account%100 | sort -u)
MONTH=""

usage() {
    cat <<EOF
Usage:
  $0 [--output-path PATH] [--grant GRANT] [--month YYYY-MM]

Options:
  --output-path PATH
                     Root directory for reports.
                     Default: directory containing this script.

  --grant GRANT      Optional Slurm grant_name (or account) filter.
                     If omitted, reports all jobs visible to sacct for \$USER.

  --month YYYY-MM    Month to report.
                     If omitted, the previous calendar month is used.

  -h, --help         Show this help.

Examples:
  $0

  $0 --month 2026-07

  $0 --grant grant_name

  $0 --output-path /some/other/path --month 2026-07

  $0 \
    --output-path /some/other/path \
    --grant grant_name \
    --month 2026-07
EOF
}

# ============================================================
# Parse arguments
# ============================================================

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output-path)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --output-path requires a value" >&2
                exit 1
            fi
            OUTPUT_PATH="$2"
            shift 2
            ;;

        --grant)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --grant requires a value" >&2
                exit 1
            fi
            GRANT="$2"
            shift 2
            ;;

        --month)
            if [[ $# -lt 2 ]]; then
                echo "ERROR: --month requires a value" >&2
                exit 1
            fi
            MONTH="$2"
            shift 2
            ;;

        -h|--help)
            usage
            exit 0
            ;;

        *)
            echo "ERROR: unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

# ============================================================
# Determine month
# ============================================================

# Default: previous calendar month.
if [[ -z "$MONTH" ]]; then
    MONTH=$(date -d "$(date +%Y-%m-01) -1 month" +%Y-%m)
fi

# Check format.
if [[ ! "$MONTH" =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
    echo "ERROR: --month must have format YYYY-MM" >&2
    exit 1
fi

# Check whether the month is actually valid.
if ! date -d "${MONTH}-01" '+%Y-%m' >/dev/null 2>&1; then
    echo "ERROR: invalid month: $MONTH" >&2
    exit 1
fi

START="${MONTH}-01"
END=$(date -d "$START +1 month" +%Y-%m-%d)

# ============================================================
# Output paths
# ============================================================

OUTDIR="$OUTPUT_PATH/$MONTH"
mkdir -p "$OUTDIR"

CSV="$OUTDIR/${USER}-${MONTH}.csv"

# Write to a temporary file first.
# TMP is created in the same filesystem so the final mv is atomic.
TMP=$(mktemp "$OUTDIR/.${USER}-${MONTH}.XXXXXX")
trap 'rm -f "$TMP"' EXIT

# ============================================================
# Build sacct arguments
# ============================================================

SACCT_ARGS=(
    --user="$USER"
    --starttime="$START"
    --endtime="$END"
    --noheader
    --parsable2
    --delimiter=","
    --format=JobID,JobName,User,Account,State,Submit,Start,End,Elapsed,ReqMem,MaxRSS
)

# Filter by Slurm account/grant only when explicitly requested.
if [[ -n "$GRANT" ]]; then
    SACCT_ARGS+=(--accounts="$GRANT")
fi

# ============================================================
# Generate report
# ============================================================

{
    echo "JobID,JobName,User,Account,State,Submit,Start,End,Elapsed,ReqMem,MaxRSS"

    sacct "${SACCT_ARGS[@]}"
} > "$TMP"

mv "$TMP" "$CSV"
trap - EXIT

# ============================================================
# Summary
# ============================================================

echo "$(date '+%Y-%m-%d %H:%M:%S') OK user=$USER month=$MONTH grant=${GRANT:-all} csv=$CSV"