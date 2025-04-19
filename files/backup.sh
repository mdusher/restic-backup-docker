#!/bin/sh

RESTIC_BACKUP_LOG="/var/log/backup-last.log"
RESTIC_MAIL_LOG="/var/log/mail-last.log"
RESTIC_ERROR_LOG="/var/log/backup-error-last.log"

copyErrorLog() {
  cp "${RESTIC_BACKUP_LOG}" "${RESTIC_ERROR_LOG}"
}

log() { echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "${RESTIC_BACKUP_LOG}"; }
log_and_echo() { echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a "${RESTIC_BACKUP_LOG}" ; }

if [ -f "/hooks/pre-backup.sh" ]; then
  log "Starting pre-backup script ..."
  /hooks/pre-backup.sh
fi

timer_start=`date +%s`
rm -f "${RESTIC_BACKUP_LOG}" "${RESTIC_MAIL_LOG}"
log_and_echo "Starting Backup"
log "BACKUP_CRON: ${BACKUP_CRON}"
log "RESTIC_REPOSITORY: ${RESTIC_REPOSITORY}"
[ ! -z "${RESTIC_TAG}" ] && log "RESTIC_TAG: ${RESTIC_TAG}"
[ ! -z "${RESTIC_FORGET_ARGS}" ] && log "RESTIC_FORGET_ARGS: ${RESTIC_FORGET_ARGS}"
[ ! -z "${RESTIC_JOB_ARGS}" ] && log "RESTIC_JOB_ARGS: ${RESTIC_JOB_ARGS}"
[ ! -z "${AWS_ACCESS_KEY_ID}" ] && log "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}"
[ ! -z "${B2_ACCOUNT_ID}" ] && log "B2_ACCOUNT_ID: ${B2_ACCOUNT_ID}"

# Do not save full backup log to logfile but to backup-last.log
backup_rc=1
if [ -z "${RESTIC_TAG}" ]; then
  restic backup /data ${RESTIC_JOB_ARGS} >> ${RESTIC_BACKUP_LOG} 2>&1
  backup_rc=$?
else
  restic backup /data ${RESTIC_JOB_ARGS} --tag="${RESTIC_TAG}" >> ${RESTIC_BACKUP_LOG} 2>&1
  backup_rc=$?
fi

log "Finished backup at $(date)"
if [ "${backup_rc}" -eq 0 ]; then
    log_and_echo "Backup Successful"
else
    log_and_echo "Backup Failed with Status ${backup_rc}"
    restic unlock
    copyErrorLog
fi

if [ "${backup_rc}" -eq 0 -a -n "${RESTIC_FORGET_ARGS}" ]; then
    log_and_echo "Forget about old snapshots based on RESTIC_FORGET_ARGS = ${RESTIC_FORGET_ARGS}"
    restic forget ${RESTIC_FORGET_ARGS} >> ${RESTIC_BACKUP_LOG} 2>&1
    rc=$?
    log "Finished forget at $(date)"
    if [[ $rc == 0 ]]; then
        log_and_echo "Forget Successful"
    else
        log_and_echo "Forget Failed with Status ${rc}"
        restic unlock
        copyErrorLog
    fi
fi

timer_end=`date +%s`
log_and_echo "Finished Backup at $(date +"%Y-%m-%d %H:%M:%S") after $((timer_end-timer_start)) seconds"

if [ -n "${MAILX_ARGS}" ]; then
    sh -c "mail -v -S sendwait ${MAILX_ARGS} < ${RESTIC_BACKUP_LOG} > ${RESTIC_MAIL_LOG} 2>&1"
    if [ $? == 0 ]; then
        log_and_echo "Mail notification successfully sent."
    else
        log_and_echo "Sending mail notification FAILED. Check ${RESTIC_MAIL_LOG} for further information."
    fi
fi

if [ -f "/hooks/post-backup.sh" ]; then
    log_and_echo "Starting post-backup script ..."
    /hooks/post-backup.sh $backup_rc
fi