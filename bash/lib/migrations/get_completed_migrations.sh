#!/bin/bash

function get_completed_migrations() {
    # Step 1: Get the container ID of the Supabase Postgres database instance
    CONTAINER_ID=$(docker ps --filter "name=supabase-db" --format "{{.ID}}")
    if [ -z "$CONTAINER_ID" ]; then
        echo "Error: Supabase Postgres container not found."
        exit 1
    fi
    # echo "Container ID: $CONTAINER_ID"

    # Step 2: Execute the SQL query to select all names from public.migrations
    result=$(docker exec -it "$CONTAINER_ID" bash -c '
        psql -U postgres -d postgres -t -c "SELECT name FROM public.migrations;"
    ')
    # Step 3: Clean up the result and convert to an array
    mapfile -t migration_names <<< "$(echo "$result" | sed '/^$/d; s/^ *//; s/ *$//' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Step 4: Print the migration names
    printf '%s\n' "${migration_names[@]}"
}

# get_completed_migrations
# echo completed