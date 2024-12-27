#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/get_completed_migrations.sh"
source "$(dirname "${BASH_SOURCE[0]}")/get_migration_files.sh"

function get_pending_migrations() {
    # Get sorted migration files
    mapfile -t sorted_files < <(get_migration_files)

    # Get completed migrations
    mapfile -t completed_migrations < <(get_completed_migrations)

    # Initialize an array to store pending migrations
    pending_migrations=()

    # Loop through sorted files and check if they're in completed migrations
    for file in "${sorted_files[@]}"; do
        if ! printf '%s\n' "${completed_migrations[@]}" | grep -qx "$file"; then
            pending_migrations+=("$file")
        fi
    done

    # Return the pending migrations
    if [ ${#pending_migrations[@]} -eq 0 ]; then
        echo ""
    else
        printf '%s\n' "${pending_migrations[@]}"
    fi
}

# get_pending_migrations