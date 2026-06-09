#!/usr/bin/env bash

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Check for GitHub CLI
if ! command -v gh &>/dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed.${NC}"
    echo "Please install it via: brew install gh"
    exit 1
fi

# Check authentication
if ! gh auth status &>/dev/null; then
    echo -e "${RED}Error: GitHub CLI is not authenticated.${NC}"
    echo "Please login by running: gh auth login"
    exit 1
fi

TYPE=""
OWNER=""

# Support command line arguments or prompt if empty
if [[ -n "${1:-}" && -n "${2:-}" ]]; then
    TYPE="$1"
    OWNER="$2"
else
    echo -e "${CYAN}${BOLD}╔═════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║        🐙 GITHUB REPO MANAGER           ║${NC}"
    echo -e "${CYAN}${BOLD}╚═════════════════════════════════════════╝${NC}"
    echo ""
    echo "  1) User Account"
    echo "  2) Organization"
    printf "  Select owner type [1-2]: "
    read -r TYPE_CHOICE
    case $TYPE_CHOICE in
        1) TYPE="user" ;;
        2) TYPE="org" ;;
        *) echo -e "${RED}Invalid choice. Exiting.${NC}"; exit 1 ;;
    esac
    printf "  Enter username/organization name: "
    read -r OWNER
    if [[ -z "$OWNER" ]]; then
        echo -e "${RED}Owner name cannot be empty. Exiting.${NC}"
        exit 1
    fi
fi

echo -e "\n${BLUE}Fetching repositories for $OWNER...${NC}"

# Fetch repository names
REPOS=$(gh repo list "$OWNER" --limit 1000 --json name -q '.[].name' 2>/dev/null || true)

if [[ -z "$REPOS" ]]; then
    echo -e "${YELLOW}No repositories found or failed to list repositories for $OWNER.${NC}"
    exit 0
fi

# Count repositories
REPO_COUNT=$(echo "$REPOS" | wc -l | xargs)

echo -e "${GREEN}Found $REPO_COUNT repositories:${NC}"
echo -e "${DIM}$REPOS${NC}"
echo ""

echo -e "${BOLD}Select bulk action to perform:${NC}"
echo -e "  ${BOLD}1)${NC} 🔒 Make all repositories ${BOLD}PRIVATE${NC}"
echo -e "  ${BOLD}2)${NC} 🔓 Make all repositories ${BOLD}PUBLIC${NC}"
echo -e "  ${BOLD}3)${NC} 🗑️  ${RED}${BOLD}DELETE${NC} all repositories (Highly Dangerous)"
echo -e "  ${BOLD}4)${NC} ❌ Exit"
printf "  Select option [1-4]: "
read -r ACTION_CHOICE

case $ACTION_CHOICE in
    1) # Make Private
        printf "  Are you sure you want to make all $REPO_COUNT repositories PRIVATE? (y/N): "
        read -r CONFIRM
        if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Aborted.${NC}"
            exit 0
        fi

        echo -e "\n${BLUE}Updating repositories to PRIVATE...${NC}"
        for repo in $REPOS; do
            FULL="$OWNER/$repo"
            echo "  Making $FULL private..."
            gh repo edit "$FULL" --visibility private --accept-visibility-change-consequences
        done
        echo -e "\n${GREEN}All repositories are now PRIVATE.${NC}"
        ;;

    2) # Make Public
        printf "  Are you sure you want to make all $REPO_COUNT repositories PUBLIC? (y/N): "
        read -r CONFIRM
        if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Aborted.${NC}"
            exit 0
        fi

        echo -e "\n${BLUE}Updating repositories to PUBLIC...${NC}"
        for repo in $REPOS; do
            FULL="$OWNER/$repo"
            echo "  Making $FULL public..."
            gh repo edit "$FULL" --visibility public --accept-visibility-change-consequences
        done
        echo -e "\n${GREEN}All repositories are now PUBLIC.${NC}"
        ;;

    3) # Bulk Delete
        echo -e "\n${RED}${BOLD}⚠️  WARNING: YOU ARE ABOUT TO DELETE ALL $REPO_COUNT REPOSITORIES FOR $OWNER! ⚠️${NC}"
        echo -e "${RED}This action is permanent, completely deletes all code/issues/PRs, and CANNOT BE UNDONE!${NC}"
        printf "  Are you absolutely sure you want to proceed? (y/N): "
        read -r CONFIRM1
        if [[ ! "$CONFIRM1" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Aborted.${NC}"
            exit 0
        fi

        printf "  Type ${BOLD}'$OWNER'${NC} to confirm deletion: "
        read -r CONFIRM2
        if [[ "$CONFIRM2" != "$OWNER" ]]; then
            echo -e "${RED}Confirmation mismatch. Aborting.${NC}"
            exit 1
        fi

        echo -e "\n${RED}Deleting repositories...${NC}"
        for repo in $REPOS; do
            FULL="$OWNER/$repo"
            echo "  Deleting $FULL..."
            gh repo delete "$FULL" --yes
        done
        echo -e "\n${GREEN}All $REPO_COUNT repositories have been DELETED.${NC}"
        ;;

    *)
        echo -e "${YELLOW}Exited without changes.${NC}"
        exit 0
        ;;
esac