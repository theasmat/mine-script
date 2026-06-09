#!/bin/bash

set -e

TYPE=$1
OWNER=$2

if [ -z "$TYPE" ] || [ -z "$OWNER" ]; then
    echo "Usage:"
    echo "./make_repos_private.sh user <username>"
    echo "./make_repos_private.sh org <orgname>"
    exit 1
fi

echo "Fetching repositories..."

REPOS=$(gh repo list "$OWNER" --limit 1000 --json name -q '.[].name')

echo ""
echo "Owner: $OWNER"
echo "Repositories found:"
echo "$REPOS"
echo ""

read -p "Continue making all repos PRIVATE? (y/n): " CONFIRM

if [[ "$CONFIRM" != "y" ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Updating repositories..."

for repo in $REPOS
do
    FULL="$OWNER/$repo"

    echo "Making $FULL private..."

    gh repo edit "$FULL" \
        --visibility private \
        --accept-visibility-change-consequences

done

echo ""
echo "All repositories are now PRIVATE."