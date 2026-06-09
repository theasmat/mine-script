#!/usr/bin/env bash

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# --- Icons ---
CHECK="✅"
ERROR="❌"
WARNING="⚠️"
INFO="ℹ️"
KEY="🔑"
ROCKET="🚀"
TRASH="🗑️"
LINK="🔗"

SSH_DIR="$HOME/.ssh"
CONFIG_FILE="$SSH_DIR/config"

# --- Helper Functions ---
print_header() {
    clear
    echo -e "${CYAN}${BOLD}╔═════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║        🔑 SSH IDENTITY MANAGER          ║${NC}"
    echo -e "${CYAN}${BOLD}╚═════════════════════════════════════════╝${NC}"
    echo ""
}

print_subheader() {
    echo -e "\n  ${MAGENTA}${BOLD}── $1 ──${NC}\n"
}

print_step() {
    echo -e "\n  ${BLUE}${BOLD}==>${NC} ${BOLD}$1${NC}"
}

print_success() {
    echo -e "  ${GREEN}${CHECK}${NC} $1"
}

print_error() {
    echo -e "  ${RED}${ERROR}${NC} $1"
}

print_warning() {
    echo -e "  ${YELLOW}${WARNING}${NC} $1"
}

print_info() {
    echo -e "  ${CYAN}${INFO}${NC} $1"
}

# Helper to find identity file for a specific Host Alias
get_identity_file() {
    local target_alias="$1"
    if [[ ! -f "$CONFIG_FILE" ]]; then
        return
    fi

    local current_host=""
    local id_file=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(echo "$line" | xargs)
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        if [[ "$line" =~ ^Host[[:space:]]+(.+) ]]; then
            if [[ "$current_host" == "$target_alias" && -n "$id_file" ]]; then
                echo "$id_file"
                return
            fi
            current_host="${BASH_REMATCH[1]}"
            id_file=""
        elif [[ "$line" =~ ^IdentityFile[[:space:]]+(.+) ]]; then
            id_file="${BASH_REMATCH[1]}"
        fi
    done < "$CONFIG_FILE"

    if [[ "$current_host" == "$target_alias" && -n "$id_file" ]]; then
        echo "$id_file"
        return
    fi
}

# Cleanly delete a Host block from config
delete_identity_from_config() {
    local target_alias="$1"
    local temp_config
    temp_config=$(mktemp)

    awk -v target="$target_alias" '
        BEGIN { skip = 0 }
        /^[^\t ]/ && !/^$/ {
            if ($1 == "Host" && $2 == target) {
                skip = 1
            } else {
                skip = 0
            }
        }
        {
            if (!skip) {
                print $0
            }
        }
    ' "$CONFIG_FILE" > "$temp_config"

    mv "$temp_config" "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
}

# --- Main Functions ---

# 1. List existing SSH configurations
list_identities() {
    print_header
    print_subheader "🔑 Active SSH Identities"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_info "No SSH config file found at $CONFIG_FILE."
        return
    fi

    local host_count
    host_count=$(grep -c "^Host " "$CONFIG_FILE" || true)

    if [[ "$host_count" -eq 0 ]]; then
        print_info "No custom hosts configured in $CONFIG_FILE."
        return
    fi

    echo -e "  ${CYAN}${BOLD}----------------------------------------------------------------------${NC}"
    printf "  %-20s %-22s %-25s\n" "Alias (Host)" "Domain (HostName)" "Identity File"
    echo -e "  ${CYAN}${BOLD}----------------------------------------------------------------------${NC}"

    local current_host=""
    local hostname=""
    local identityfile=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(echo "$line" | xargs)
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        if [[ "$line" =~ ^Host[[:space:]]+(.+) ]]; then
            if [[ -n "$current_host" ]]; then
                printf "  %-20s %-22s %-25s\n" "$current_host" "${hostname:-N/A}" "${identityfile:-N/A}"
            fi
            current_host="${BASH_REMATCH[1]}"
            hostname=""
            identityfile=""
        elif [[ "$line" =~ ^HostName[[:space:]]+(.+) ]]; then
            hostname="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^IdentityFile[[:space:]]+(.+) ]]; then
            identityfile="${BASH_REMATCH[1]}"
        fi
    done < "$CONFIG_FILE"

    if [[ -n "$current_host" ]]; then
        printf "  %-20s %-22s %-25s\n" "$current_host" "${hostname:-N/A}" "${identityfile:-N/A}"
    fi
    echo -e "  ${CYAN}${BOLD}----------------------------------------------------------------------${NC}"
}

# 2. Create new identity
create_identity() {
    print_header
    print_subheader "🆕 Create New SSH Identity"
    
    local SERVICE_CHOICE=""
    local SERVICE=""
    local HOSTNAME=""
    local ALIAS=""
    local LABEL=""
    local KEY_PATH=""
    local EMAIL=""
    local KEY_TYPE_CHOICE=""
    local KEY_TYPE=""
    local PASSPHRASE=""
    local PASSPHRASE_CONFIRM=""
    local OVERWRITE_KEY=""
    local OVERWRITE_CONFIG=""
    
    # Step 1: Git Service
    print_step "Step 1: Choose Git Service"
    echo "  1) GitHub (github.com)"
    echo "  2) GitLab (gitlab.com)"
    echo "  3) Bitbucket (bitbucket.org)"
    echo "  4) Custom"
    printf "  Select option [1-4]: "
    read -r SERVICE_CHOICE

    case $SERVICE_CHOICE in
      1) SERVICE="github"; HOSTNAME="github.com" ;;
      2) SERVICE="gitlab"; HOSTNAME="gitlab.com" ;;
      3) SERVICE="bitbucket"; HOSTNAME="bitbucket.org" ;;
      4)
        printf "  Enter service name (e.g., company): "
        read -r SERVICE
        printf "  Enter host domain (e.g., git.company.com): "
        read -r HOSTNAME
        ;;
      *)
        print_error "Invalid choice."
        return 1
        ;;
    esac

    # Step 2: Alias name
    print_step "Step 2: SSH Alias"
    echo -e "  ${CYAN}Info:${NC} This is the host alias used in 'git clone' (e.g., github-work, gitlab-personal)"
    printf "  Alias host name: "
    read -r ALIAS

    if [[ -z "$ALIAS" ]]; then
        print_error "Alias cannot be empty."
        return 1
    fi

    if grep -q "^Host $ALIAS$" "$CONFIG_FILE" 2>/dev/null; then
        print_warning "Alias '$ALIAS' already exists in $CONFIG_FILE."
        printf "  Do you want to overwrite the existing configuration for this alias? (y/N): "
        read -r OVERWRITE_CONFIG
        if [[ "$OVERWRITE_CONFIG" =~ ^[Yy]$ ]]; then
            delete_identity_from_config "$ALIAS"
            print_success "Existing alias '$ALIAS' configuration removed."
        else
            print_warning "Aborting creation to prevent duplication."
            return 0
        fi
    fi

    # Step 3: Key label
    print_step "Step 3: Key Label"
    echo -e "  ${CYAN}Info:${NC} Used to name the key file (e.g., work, personal, core)"
    printf "  Key label: "
    read -r LABEL

    if [[ -z "$LABEL" ]]; then
        print_error "Label cannot be empty."
        return 1
    fi

    KEY_PATH="$SSH_DIR/id_${SERVICE}_${LABEL}"

    if [[ -f "$KEY_PATH" ]]; then
        print_warning "SSH key already exists at $KEY_PATH."
        printf "  Do you want to overwrite it? All previous access will be lost! (y/N): "
        read -r OVERWRITE_KEY
        if [[ ! "$OVERWRITE_KEY" =~ ^[Yy]$ ]]; then
            print_warning "Aborting key generation."
            return 0
        fi
    fi

    # Step 4: Email/Comment
    print_step "Step 4: Key Comment / Email"
    printf "  Email or comment for key: "
    read -r EMAIL

    if [[ -z "$EMAIL" ]]; then
        print_error "Email/Comment cannot be empty."
        return 1
    fi

    # Step 5: Key type
    print_step "Step 5: Choose Key Type"
    echo "  1) ed25519 (Recommended, more secure & faster)"
    echo "  2) rsa (Legacy, 4096-bit)"
    printf "  Select option [1-2] (default 1): "
    read -r KEY_TYPE_CHOICE

    if [[ "$KEY_TYPE_CHOICE" == "2" ]]; then
        KEY_TYPE="rsa"
    else
        KEY_TYPE="ed25519"
    fi

    # Step 6: Passphrase
    print_step "Step 6: Passphrase"
    echo -e "  ${CYAN}Info:${NC} Leave empty for no passphrase (not recommended for sensitive keys)."
    printf "  Enter passphrase: "
    read -r -s PASSPHRASE
    echo
    printf "  Confirm passphrase: "
    read -r -s PASSPHRASE_CONFIRM
    echo

    if [[ "$PASSPHRASE" != "$PASSPHRASE_CONFIRM" ]]; then
        print_error "Passphrases do not match."
        return 1
    fi

    # --- Execution ---
    print_step "Generating SSH key..."
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"

    if [[ -f "$KEY_PATH" ]]; then
        rm -f "$KEY_PATH" "${KEY_PATH}.pub"
    fi

    local gen_status=0
    if [[ "$KEY_TYPE" == "rsa" ]]; then
        ssh-keygen -t "$KEY_TYPE" -b 4096 -C "$EMAIL" -f "$KEY_PATH" -N "$PASSPHRASE" || gen_status=$?
    else
        ssh-keygen -t "$KEY_TYPE" -C "$EMAIL" -f "$KEY_PATH" -N "$PASSPHRASE" || gen_status=$?
    fi

    if [[ $gen_status -ne 0 ]]; then
        print_error "Failed to generate key pair."
        return 1
    fi

    print_success "Key pair generated at $KEY_PATH"

    print_step "Updating SSH config..."
    touch "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"

    cat >> "$CONFIG_FILE" <<EOF

# Added by SSH Identity Manager on $(date +%F)
Host $ALIAS
    HostName $HOSTNAME
    User git
    IdentityFile $KEY_PATH
    IdentitiesOnly yes
EOF

    print_success "SSH config updated."

    print_step "Starting ssh-agent and adding key..."
    if ! pgrep -u "$USER" ssh-agent > /dev/null; then
        eval "$(ssh-agent -s)" >/dev/null
        print_success "Started new ssh-agent."
    else
        print_success "ssh-agent is already running."
    fi

    # Use ssh-add with specific arguments based on the OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ssh-add -h 2>&1 | grep -q 'apple-use-keychain'; then
            ssh-add --apple-use-keychain "$KEY_PATH"
        elif ssh-add -h 2>&1 | grep -q '\-K'; then
            ssh-add -K "$KEY_PATH"
        else
            ssh-add "$KEY_PATH"
        fi
    else
        ssh-add "$KEY_PATH"
    fi

    print_success "Identity added to ssh-agent."

    # --- Summary ---
    echo -e "\n${GREEN}${BOLD}=======================================${NC}"
    echo -e "${GREEN}${BOLD}   🎉 SSH Identity Created Successfully!  ${NC}"
    echo -e "${GREEN}${BOLD}=======================================${NC}\n"

    echo -e "  ${YELLOW}Here is your public key:${NC}"
    echo -e "  ---------------------------------------"
    sed 's/^/  /' "${KEY_PATH}.pub"
    echo -e "  ---------------------------------------"

    if command -v pbcopy >/dev/null 2>&1; then
        cat "${KEY_PATH}.pub" | pbcopy
        print_success "Public key copied to clipboard! 📋"
    elif command -v xclip >/dev/null 2>&1; then
        cat "${KEY_PATH}.pub" | xclip -selection clipboard
        print_success "Public key copied to clipboard! 📋"
    else
        echo -e "\n  ${CYAN}Add this key to your Git service account settings.${NC}"
    fi

    echo -e "\n  ${BOLD}Next steps:${NC}"
    echo -e "  1. Paste the public key into your Git hosting account."
    echo -e "  2. Test the connection with option 3 (Test connection) or run:"
    echo -e "     ${CYAN}ssh -T git@$ALIAS${NC}"
    echo -e "  3. Clone a repository using your new alias:"
    echo -e "     ${CYAN}git clone git@$ALIAS:username/repository.git${NC}\n"
}

# 3. Test Connection
test_identity() {
    list_identities
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        return
    fi
    
    local host_count
    host_count=$(grep -c "^Host " "$CONFIG_FILE" || true)
    [[ "$host_count" -eq 0 ]] && return

    echo ""
    local test_alias=""
    printf "  Enter the Host Alias to test (or press Enter to cancel): "
    read -r test_alias
    [[ -z "$test_alias" ]] && return

    if ! grep -q "^Host $test_alias$" "$CONFIG_FILE" 2>/dev/null; then
        print_error "Alias '$test_alias' not found in config."
        return
    fi

    print_step "Testing connection to '$test_alias'..."
    local output
    # ssh -T returns status 1 for success on GitHub, so we temporarily disable set -e
    output=$(ssh -T -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "$test_alias" 2>&1 || true)

    echo -e "\n  ${DIM}${output}${NC}\n"

    # Some git services return specific strings on success
    if echo "$output" | grep -Eiq "successfully authenticated|welcome|logged in|authorized"; then
        print_success "Connection successful!"
    else
        print_warning "Connection finished. Verify from the server response above if access is working."
    fi
}

# 4. Delete Identity
delete_identity() {
    list_identities
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        return
    fi

    local host_count
    host_count=$(grep -c "^Host " "$CONFIG_FILE" || true)
    [[ "$host_count" -eq 0 ]] && return

    echo ""
    local delete_alias=""
    printf "  Enter the Host Alias to delete (or press Enter to cancel): "
    read -r delete_alias
    [[ -z "$delete_alias" ]] && return

    if ! grep -q "^Host $delete_alias$" "$CONFIG_FILE" 2>/dev/null; then
        print_error "Alias '$delete_alias' not found in config."
        return
    fi

    local raw_path
    raw_path=$(get_identity_file "$delete_alias")
    local filepath=""
    if [[ -n "$raw_path" ]]; then
        filepath="${raw_path/#\~/$HOME}"
    fi

    echo ""
    printf "  Are you sure you want to delete '$delete_alias' from SSH config? (y/N): "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Deletion aborted."
        return
    fi

    delete_identity_from_config "$delete_alias"
    print_success "Removed '$delete_alias' from SSH config."

    if [[ -n "$filepath" ]]; then
        # Check if files exist
        if [[ -f "$filepath" || -f "${filepath}.pub" ]]; then
            echo ""
            printf "  Do you also want to delete the corresponding key files? ($filepath) (y/N): "
            read -r delete_keys
            if [[ "$delete_keys" =~ ^[Yy]$ ]]; then
                rm -f "$filepath" "${filepath}.pub"
                print_success "Deleted key files."
            fi
        fi
    fi
}

# --- Main Flow ---
main() {
    while true; do
        print_header
        echo -e "  ${BOLD}1.${NC} 🔑 List existing SSH identities"
        echo -e "  ${BOLD}2.${NC} 🆕 Create a new SSH identity"
        echo -e "  ${BOLD}3.${NC} 🔗 Test an identity connection"
        echo -e "  ${BOLD}4.${NC} 🗑️  Delete an SSH identity"
        echo -e "  ${BOLD}5.${NC} ❌ Exit"
        echo ""
        local menu_choice=""
        printf "  Select option [1-5]: "
        read -r menu_choice
        case $menu_choice in
            1) list_identities; echo; printf "  Press ENTER to return to menu..."; read -r;;
            2) create_identity; echo; printf "  Press ENTER to return to menu..."; read -r;;
            3) test_identity; echo; printf "  Press ENTER to return to menu..."; read -r;;
            4) delete_identity; echo; printf "  Press ENTER to return to menu..."; read -r;;
            5) print_info "Exiting SSH Identity Manager. Bye!"; exit 0;;
            *) print_error "Invalid option."; sleep 1;;
        esac
    done
}

main "$@"