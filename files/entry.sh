#!/bin/sh

log() { echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1"; }

log "Starting container ..."

log "Checking for required config"
missing_config=0
for e in RESTIC_REPOSITORY RESTIC_PASSWORD BACKUP_CRON; do
  e_val_len="$(env | awk -F'=' "/^${e}=/ {print \$2}" | wc -c)"
  if [ "${e_val_len}" -eq 0 ]; then
    log "${e} is a required environment variable."
    missing_config=1
  fi
done
# Exit if a required environment variable is missing
if [ "${missing_config}" -eq 1 ]; then
  exit 1
fi

restic snapshots ${RESTIC_INIT_ARGS} &>/dev/null
status=$?
log "Check Repo status $status"

if [ $status != 0 ]; then
  log "Restic repository '${RESTIC_REPOSITORY}' does not exists. Running restic init."
  restic init ${RESTIC_INIT_ARGS}
  init_status=$?
  log "Repo init status $init_status"
  if [ $init_status != 0 ]; then
    log "Failed to init the repository: '${RESTIC_REPOSITORY}'"
    exit 1
  fi
fi

log "Setup backup cron job with cron expression BACKUP_CRON: ${BACKUP_CRON}"
echo "${BACKUP_CRON} /usr/bin/flock -n /var/run/backup.lock /bin/backup >> /proc/1/fd/1 2>&1" > /var/spool/cron/crontabs/root

# If CHECK_CRON is set we will enable automatic backup checking
if [ -n "${CHECK_CRON}" ]; then
  log "Setup check cron job with cron expression CHECK_CRON: ${CHECK_CRON}"
  echo "${CHECK_CRON} /usr/bin/flock -n /var/run/backup.lock /bin/check >> /proc/1/fd/1 2>&1" >> /var/spool/cron/crontabs/root
fi

# Make sure the file exists before we start tail
touch /var/log/cron.log

# Supress rclone config missing warnings by making 
# sure the config file exists
RCLONE_CONF="$HOME/.config/rclone/rclone.conf"
if [ ! -f "${RCLONE_CONF}" ]; then
  mkdir -p "$(dirname "${RCLONE_CONF}")"
  touch "${RCLONE_CONF}"
fi

log "Container started."

exec "$@"