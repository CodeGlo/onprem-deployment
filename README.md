# ODIN DEPLOYMENT REPO

## PreReqs

1. Docker
2. git
3. bash version 5.x

## Cloning

`git clone --recurse-submodules https://github.com/CodeGlo/onprem-deployment.git`

## Initial Setup

1. `bash setup.sh`
2. load admin panel and enter values...

## Startup

1. `docker compose up -d`

## DB Setup

1. run `bash bash/run_migration.sh`
