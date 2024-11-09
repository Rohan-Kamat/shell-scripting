#!/bin/bash

# Check if commit hash is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <commit-hash>"
    exit 1
fi

COMMIT_HASH=$1

# Validate if the commit exists in main branch
if ! git rev-parse --verify "$COMMIT_HASH" >/dev/null 2>&1; then
    echo "Error: Commit $COMMIT_HASH does not exist"
    exit 1
fi

# Store current branch
CURRENT_BRANCH=$(git symbolic-ref --short HEAD)

# Fetch all remote branches
git fetch --all

# Get all remote branches excluding main
REMOTE_BRANCHES=$(git branch -r | grep -v "main" | grep -v "HEAD" | sed 's/origin\///')

# Counter for successful operations
SUCCESS_COUNT=0
TOTAL_BRANCHES=0

for BRANCH in $REMOTE_BRANCHES; do
    TOTAL_BRANCHES=$((TOTAL_BRANCHES + 1))
    echo "Processing branch: $BRANCH"
    
    # Check if branch exists locally
    if ! git show-ref --verify --quiet "refs/heads/$BRANCH"; then
        git checkout -b "$BRANCH" "origin/$BRANCH"
    else
        git checkout "$BRANCH"
    fi
    
    # Check if commit already exists in this branch
    if git cherry "$BRANCH" "$COMMIT_HASH" | grep -q "^-"; then
        echo "Commit already exists in $BRANCH, skipping..."
        continue
    fi
    
    # Attempt to cherry-pick
    if git cherry-pick "$COMMIT_HASH"; then
        echo "Successfully cherry-picked commit to $BRANCH"
        git push origin "$BRANCH"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "Cherry-pick failed for $BRANCH"
        git cherry-pick --abort
    fi
done

# Return to original branch
git checkout "$CURRENT_BRANCH"

# Summary
echo "Cherry-pick operation completed"
echo "Successfully processed $SUCCESS_COUNT out of $TOTAL_BRANCHES branches"