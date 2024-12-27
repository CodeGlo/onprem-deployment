#!/bin/bash

# function run_schema_migration() {
#     # Step 1: Get the container ID of the Supabase Postgres database instance
#     CONTAINER_ID=$(docker ps --filter "name=supabase-db" --format "{{.ID}}")

#     if [ -z "$CONTAINER_ID" ]; then
#         echo "Error: Supabase Postgres container not found."
#         exit 1
#     fi

#     echo "Container ID: $CONTAINER_ID"

#     # Step 2: Copy the migration file into the container
#     echo $PWD
#     MIGRATION_FILE="${cwd}/repos/alignment-project-server/deployment/20240617094846_base_migration.sql"

#     if [ ! -f "$MIGRATION_FILE" ]; then
#         echo "Error: Migration file not found at $MIGRATION_FILE"
#         exit 1
#     fi
#         echo "Migration file found: $MIGRATION_FILE"

#     docker cp "$MIGRATION_FILE" "$CONTAINER_ID:/tmp/migration.sql"
#     echo "Migration file copied to container"

#     # Step 3 & 4: Enter the container and run the migration script
#     docker exec -it "$CONTAINER_ID" bash -c '
#         echo "Entering container and running migration..."
#         psql -U postgres -d postgres -f /tmp/migration.sql
#         echo "Migration completed"
#     '

#     echo "Script execution finished"
# }


source "$(dirname "${BASH_SOURCE[0]}")/get_pending_migrations.sh"

function run_pending_migrations() {
    # Create a temporary directory
    mkdir -p ./tmp

    # Get the list of pending migrations
    mapfile -t pending_migrations < <(get_pending_migrations | grep -v '^[[:space:]]*$')

    if [ ${#pending_migrations[@]} -eq 0 ]; then
        echo "No pending migrations to run."
    else
        # Get the container ID of the Supabase Postgres database instance
        CONTAINER_ID=$(docker ps --filter "name=supabase-db" --format "{{.ID}}")

        if [ -z "$CONTAINER_ID" ]; then
            echo "Error: Supabase Postgres container not found."
            exit 1
        fi

        echo "Supabase DB Container ID: $CONTAINER_ID"

        echo "Pending migrations: ${pending_migrations[*]}"

        # Loop through each pending migration
        for migration in "${pending_migrations[@]}"; do
            # Copy the migration file from the fastapi_backend container
            docker cp "fastapi_backend:/app/deployment/${migration}.sql" "./tmp/${migration}.sql"
            if [ $? -ne 0 ]; then
                echo "Error: Failed to copy migration file ${migration}.sql from fastapi_backend container"
                continue
            fi

            echo "Processing migration file: ${migration}.sql"

            # Copy the migration file into the Supabase DB container
            docker cp "./tmp/${migration}.sql" "$CONTAINER_ID:/tmp/migration.sql"
            echo "Migration file copied to Supabase DB container"

            # Enter the container and run the migration script
            docker exec -it "$CONTAINER_ID" bash -c '
                echo "Entering container and running migration..."
                psql -U postgres -d postgres -f /tmp/migration.sql
                if [ $? -eq 0 ]; then
                    echo "Migration completed successfully"
                    psql -U postgres -d postgres -c "INSERT INTO public.migrations (name) VALUES ('\'$migration\'');"
                else
                    echo "Error: Migration failed"
                fi
            '

            echo "Finished processing ${migration}.sql"
        done

        echo "All pending migrations processed"
    fi

    # Delete the temporary directory
    rm -rf ./tmp
}

# Run the function
# run_schema_migrations