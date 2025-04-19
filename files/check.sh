#!/bin/sh

RESTIC_BACKUP_LOG="/var/log/backup-last.log"
RESTIC_MAIL_LOG="/var/log/mail-last.log"
RESTIC_ERROR_LOG="/var/log/backup-error-last.log"

copyErrorLog() {
  cp "${RESTIC_BACKUP_LOG}" "${RESTIC_ERROR_LOG}"
}

log() { echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "${RESTIC_BACKUP_LOG}"; }
log_and_echo() { echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a "${RESTIC_BACKUP_LOG}" ; }

copyErrorLog() {
  cp "${RESTIC_BACKUP_LOG}" "${RESTIC_ERROR_LOG}"
}

if [ -f "/hooks/pre-check.sh" ]; then
    echo "Starting pre-check script ..."
    /hooks/pre-check.sh
else
    echo "Pre-check script not found ..."
fi

timer_start=`date +%s`
rm -f ${RESTIC_BACKUP_LOG} ${RESTIC_MAIL_LOG}
log_and_echo "Starting Check at $(date)"
log "CHECK_CRON: ${CHECK_CRON}"
log "RESTIC_REPOSITORY: ${RESTIC_REPOSITORY}"
[ ! -z "${RESTIC_DATA_SUBSET}" ] && log "RESTIC_DATA_SUBSET: ${RESTIC_DATA_SUBSET}"
[ ! -z "${AWS_ACCESS_KEY_ID}" ] && log "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}"
[ ! -z "${B2_ACCOUNT_ID}" ] && log "B2_ACCOUNT_ID: ${B2_ACCOUNT_ID}"

# Do not save full check log to logfile but to check-last.log
if [ -n "${RESTIC_DATA_SUBSET}" ]; then
    restic check --read-data-subset=${RESTIC_DATA_SUBSET} >> ${RESTIC_BACKUP_LOG} 2>&1
else
    restic check >> ${RESTIC_BACKUP_LOG} 2>&1
fi
check_rc=$?
log "Finished check at $(date)"
if [[ $check_rc == 0 ]]; then
    echo "Check Successful"
else
    echo "Check Failed with Status ${check_rc}"
    restic unlocks
    copyErrorLog
fi

timer_end=`date +%s`
echo "Finished Check at $(date +"%Y-%m-%d %H:%M:%S") after $((timer_end-timer_start)) seconds"

if [ -n "${MAILX_ARGS}" ]; then
    sh -c "mail -v -S sendwait ${MAILX_ARGS} < ${RESTIC_BACKUP_LOG} > ${RESTIC_MAIL_LOG} 2>&1"
    if [ $? == 0 ]; then
        echo "Mail notification successfully sent."
    else
        echo "Sending mail notification FAILED. Check ${RESTIC_MAIL_LOG} for further information."
    fi
fi

if [ -f "/hooks/post-check.sh" ]; then
    echo "Starting post-check script ..."
    /hooks/post-check.sh $check_rc
else
    echo "Post-check script not found ..."
fi
