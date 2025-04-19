FROM docker.io/alpine:latest AS rclone
# Download rclone
ARG RCLONE_VERSION=v1.69.1
ADD https://downloads.rclone.org/v1.69.1/rclone-${RCLONE_VERSION}-linux-amd64.zip /
RUN unzip rclone-${RCLONE_VERSION}-linux-amd64.zip && mv rclone-${RCLONE_VERSION}-linux-amd64/rclone /bin/rclone && chmod +x /bin/rclone

FROM docker.io/restic/restic:0.18.0

RUN apk add --update --no-cache curl s-nail

COPY --from=rclone /bin/rclone /bin/rclone

RUN mkdir -p /var/spool/cron/crontabs \
             /var/log \
             /root/.config/rclone; \
    touch /var/log/cron.log; \
    touch /root/.config/rclone/rclone.conf

ENV RESTIC_REPOSITORY=/mnt/restic
ENV RESTIC_PASSWORD=""
ENV RESTIC_TAG=""
ENV BACKUP_CRON="0 */6 * * *"
ENV CHECK_CRON=""
ENV RESTIC_INIT_ARGS=""
ENV RESTIC_FORGET_ARGS=""
ENV RESTIC_JOB_ARGS=""
ENV RESTIC_DATA_SUBSET=""
ENV MAILX_ARGS=""

# openshift fix
RUN mkdir /.cache && \
    chgrp -R 0 /.cache && \
    chmod -R g=u /.cache && \
    chgrp -R 0 /mnt && \
    chmod -R g=u /mnt && \
    chgrp -R 0 /var/spool/cron/crontabs/root && \
    chmod -R g=u /var/spool/cron/crontabs/root && \
    chgrp -R 0 /var/log/cron.log && \
    chmod -R g=u /var/log/cron.log

# /data is the dir where you have to put the data to be backed up
VOLUME /data

COPY files/backup.sh /bin/backup
COPY files/check.sh /bin/check
COPY files/entry.sh /entry.sh
RUN chmod +x /bin/backup /bin/check /entry.sh

ENTRYPOINT ["/entry.sh"]
CMD ["/usr/sbin/crond", "-f"]