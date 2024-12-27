#!/bin/bash

function run_schema_migration() {
    # Step 1: Get the container ID of the Supabase Postgres database instance
    CONTAINER_ID=$(docker ps --filter "name=supabase-db" --format "{{.ID}}")

    if [ -z "$CONTAINER_ID" ]; then
        echo "Error: Supabase Postgres container not found."
        exit 1
    fi

    echo "Container ID: $CONTAINER_ID"

    # Step 2: Copy the migration file into the container
    echo $PWD
    MIGRATION_FILE="${cwd}/repos/alignment-project-server/deployment/20240617094846_base_migration.sql"

    if [ ! -f "$MIGRATION_FILE" ]; then
        echo "Error: Migration file not found at $MIGRATION_FILE"
        exit 1
    fi
        echo "Migration file found: $MIGRATION_FILE"

    docker cp "$MIGRATION_FILE" "$CONTAINER_ID:/tmp/migration.sql"
    echo "Migration file copied to container"

    # Step 3 & 4: Enter the container and run the migration script
    docker exec -it "$CONTAINER_ID" bash -c '
        echo "Entering container and running migration..."
        psql -U postgres -d postgres -f /tmp/migration.sql
        echo "Migration completed"
    '

    echo "Script execution finished"
}
