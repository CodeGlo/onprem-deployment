#!/bin/bash

function get_migration_files() {
    # Define the directory path inside the container
    CONTAINER_DIR="/app/deployment"
    CONTAINER_NAME="fastapi_backend"

    # Check if the container is running
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Error: Container ${CONTAINER_NAME} is not running"
        return 1
    fi

    # Get all .sql files from inside the container, remove the extension, sort alpha-numerically
    migration_files=($(docker exec ${CONTAINER_NAME} find ${CONTAINER_DIR} -name "*.sql" -type f | sed 's/.*\///' | sed 's/\.sql$//' | sort -V))

    # Return the array
    printf '%s\n' "${migration_files[@]}"
}

# get_migration_files