#!/usr/bin/env bash 
set -euo pipefail
# This script downloads the SRR files from the SRA database using the pre-computed SRR list.

PROJECT=PRJNA931847
OUTFILE=metadata/srr_ids.txt
mkdir -p metadata

echo "Downloading SRR IDs for project $PROJECT..."

esearch -db sra -query "$PROJECT" | \
    efetch -format runinfo | \
    cut -d',' -f1 | grep '^SRR' | \
    sort -u > "$OUTFILE"
echo "Saved $(wc -l < $OUTFILE ) SRR IDs to $OUTFILE."