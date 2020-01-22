#!/usr/bin/env bash
set -e

while ! pg_isready -q -h $POSTGRES_HOSTNAME -p "5432" -U $POSTGRES_USER
do
  echo "Postgres is unavailable - sleeping"
  sleep 2
done

echo "Postgres is available: Running Notifir db migrations..."
/opt/app/bin/talk eval 'Talk.ReleaseTasks.migrate'


# Launch the OTP release and replace the caller as Process #1 in the container
echo "Launching Talk OTP release..."
exec /opt/app/bin/talk "$@"
