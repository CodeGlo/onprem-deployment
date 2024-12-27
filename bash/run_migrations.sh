cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export cwd
source "$(dirname "${BASH_SOURCE[0]}")/./lib/migrations/run_pending_migrations.sh"

run_pending_migrations
