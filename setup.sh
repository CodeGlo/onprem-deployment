#!/bin/bash


# Copy the environment file
cp ./env_templates/.env.supabase.template ./supabase/docker/.env

# Check if the copy was successful
if [ $? -eq 0 ]; then
    echo "Successfully copied .env.supabase to supabase/docker/.env"
else
    echo "Error: Failed to copy environment file"
    exit 1
fi
