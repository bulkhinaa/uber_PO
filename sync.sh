#!/bin/bash
# Quick sync script for manual use
git add .
git commit -m "${1:-Auto-sync: $(date '+%Y-%m-%d %H:%M:%S')}"
# Push happens automatically via post-commit hook
