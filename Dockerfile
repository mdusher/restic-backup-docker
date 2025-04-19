FROM docker.io/alpine:latest AS rclone
# Download rclone
ARG RCLONE_VERSION=v1.69.1
ARG RCLONE_ARCH=amd64
ADD https://downloads.rclone.org/v1.69.1/rclone-${RCLONE_VERSION}-linux-${RCLONE_ARCH}.zip /
RUN unzip rclone-${RCLONE_VERSION}-linux-${RCLONE_ARCH}.zip \
    && mv rclone-${RCLONE_VERSION}-linux-${RCLONE_ARCH}/rclone /bin/rclone \
    && chmod +x /bin/rclone

FROM docker.io/restic/restic:0.18.0

RUN apk add --update --no-cache curl s-nail

COPY --from=rclone /bin/rclone /bin/rclone

RUN mkdir -p /var/spool/cron/crontabs \
             /var/log \
             /root/.config/rclone; \
    touch /var/log/cron.log; \
    touch /root/.config/rclone/rclone.conf

ENV BACKUP_CRON="0 */6 * * *"

# /data is where the container expects the data for backing up to be mounted
VOLUME /data

COPY files/backup.sh /bin/backup
COPY files/check.sh /bin/check
COPY files/entry.sh /entry.sh
RUN chmod +x /bin/backup /bin/check /entry.sh

ENTRYPOINT ["/entry.sh"]
CMD ["/usr/sbin/crond", "-f"]