# Restic Backup Docker Container
A docker container to automate [restic backups](https://restic.github.io/)

This container runs restic backups in regular intervals. 

* Easy setup and maintanance
* Support for different targets (tested with: Local, NFS, SFTP, AWS)
* Support `restic mount` inside the container to browse the backup files

**Container**:
* [ghcr.io/mdusher/restic-backup-docker](https://github.com/mdusher/restic-backup-docker/pkgs/container/restic-backup-docker)

Latest master (experimental):
```
docker pull ghcr.io/mdusher/restic-backup-docker:master
```

Latest release:
```
docker pull ghcr.io/mdusher/restic-backup-docker:latest
```

# Contributing
Pull Requests to improve the image are always wellcome. Please create an issue about the PR first.

When behaviour of the image changes (Features, Bugfixes, Changes in the API) please update the "Unreleased" section of the [CHANGELOG.md](https://github.com/mdusher/restic-backup-docker/blob/master/CHANGELOG.md)


## Hooks

If you need to execute a script before or after each backup or check, you need to add your hook scripts in the container folder `/hooks`:
```
-v ~/home/user/hooks:/hooks
```

Call your pre-backup script `pre-backup.sh` and post-backup script `post-backup.sh`. You can also have separate scripts when running data verification checks `pre-check.sh` and `post-check.sh`.


## Logfiles
Logfiles are inside the container. If needed, you can create volumes for them.
```
docker logs
```
Shows `/var/log/cron.log`.

Additionally you can see the full log, including restic output, of the last execution in `/var/log/backup-last.log`. When the backup fails, the log is copied to `/var/log/restic-error-last.log`. If configured, you can find the full output of the mail notification in `/var/log/mail-last.log`.

# Use the running container

Assuming the container name is `restic-backup-var`, you can execute restic with:

    docker exec -ti restic-backup-var restic

## Backup

To execute a backup manually, independent of the CRON, run:

    docker exec -ti restic-backup-var /bin/backup
    
Back up a single file or directory:

    docker exec -ti restic-backup-var restic backup /data/path/to/dir --tag my-tag

## Data verification check

To verify backup integrity and consistency manually, independent of the CRON, run:

    docker exec -ti restic-backup-var /bin/check

## Restore

You might want to mount a separate host volume at e.g. `/restore` to not override existing data while restoring. 

Get your snapshot ID with:

    docker exec -ti restic-backup-var restic snapshots
    
e.g. `abcdef12`

     docker exec -ti restic-backup-var restic restore --include /data/path/to/files --target / abcdef12

The target is `/` since all data backed up should be inside the host mounted `/data` dir. If you mount `/restore` you should set `--target /restore` and the data will end up in `/restore/data/path/to/files`.

# Customize the Container

The container is set up by setting [environment variables](https://docs.docker.com/engine/reference/run/#/env-environment-variables) and [volumes](https://docs.docker.com/engine/reference/run/#volume-shared-filesystems).

## Environment variables

* `RESTIC_REPOSITORY` - the location of the restic repository. Default `/mnt/restic`. For S3: `s3:https://s3.amazonaws.com/BUCKET_NAME`
* `RESTIC_PASSWORD` - the password for the restic repository. Will also be used for restic init during first start when the repository is not initialized.
* `RESTIC_TAG` - Optional. To tag the images created by the container.
* `BACKUP_CRON` - A cron expression to run the backup. Note: The cron daemon uses UTC time zone. Default: `0 */6 * * *` aka every 6 hours.
* `CHECK_CRON` - Optional. A cron expression to run data integrity check (`restic check`). If left unset, data will not be checked. Note: The cron daemon uses UTC time zone. Example: `0 23 * * 3` to run 11PM every Tuesday.
* `RESTIC_FORGET_ARGS` - Optional. Only if specified, `restic forget` is run with the given arguments after each backup. Example value: `-e "RESTIC_FORGET_ARGS=--prune --keep-last 10 --keep-hourly 24 --keep-daily 7 --keep-weekly 52 --keep-monthly 120 --keep-yearly 100"`
* `RESTIC_INIT_ARGS` - Optional. Allows specifying extra arguments to `restic init` such as a password file with `--password-file`.
* `RESTIC_JOB_ARGS` - Optional. Allows specifying extra arguments to the backup job such as limiting bandwith with `--limit-upload` or excluding file masks with `--exclude`.
* `RESTIC_DATA_SUBSET` - Optional. You can pass a value to `--read-data-subset` when a repository check is run. If left unset, only the structure of the repository is verified. Note: `CHECK_CRON` must be set for check to be run automatically.
* `AWS_ACCESS_KEY_ID` - Optional. When using restic with AWS S3 storage.
* `AWS_SECRET_ACCESS_KEY` - Optional. When using restic with AWS S3 storage.
* `MAILX_ARGS` - Optional. If specified, the content of `/var/log/backup-last.log` and `/var/log/check-last.log` is sent via mail after each backup and data integrity check using an *external SMTP*. To have maximum flexibility, you have to specify the mail/smtp parameters on your own. Have a look at the [mailx manpage](https://linux.die.net/man/1/mailx) for further information. Example value: `-e "MAILX_ARGS=-r 'from@example.de' -S 'mta=submissions://username:password@smtp.example.com:465' -S v15-compat --subject "Result of the last restic run" 'to@example.com'`.

## Volumes

* `/data` - This is the data that gets backed up. Just [mount](https://docs.docker.com/engine/reference/run/#volume-shared-filesystems) it to wherever you want.

## Set the hostname

Since restic saves the hostname with each snapshot and the hostname of a docker container is derived from its id, you might want to customize this by setting the hostname of the container to another value.

Set `--hostname` in the [network settings](https://docs.docker.com/engine/reference/run/#network-settings)

## Backup via SFTP

Since restic needs a **passwordless login** to the SFTP server, make sure you can do `sftp user@host` from inside the container. If you can do so from your host system, the easiest way is to just mount your `.ssh` folder containing the authorized cert into the container by specifying `-v ~/.ssh:/root/.ssh` as an argument for `docker run`.

Now you can simply specify the restic repository to be an [SFTP repository](https://restic.readthedocs.io/en/stable/Manual/#create-an-sftp-repository).

```
-e "RESTIC_REPOSITORY=sftp:user@host:/tmp/backup"
```

## Backup via rclone

To use rclone as a backend for restic, simply add the rclone config file as a volume with `-v /absolute/path/to/rclone.conf:/root/.config/rclone/rclone.conf`.

Note that for some backends (Among them Google Drive and Microsoft OneDrive), rclone writes data back to the `rclone.conf` file. In this case it needs to be writable by Docker.

If the container fails to write the new `rclone.conf` file with the error message `Failed to save config after 10 tries: Failed to move previous config to backup location`, add the entire `rclone` directory as a volume: `-v /absolute/path/to/rclone-dir:/root/.config/rclone`.

## Example docker-compose

This is an example `docker-compose.yml`. The container will back up two directories to an SFTP server and check data integrity once a week. 

```
version: '3'

services:
  restic:
    image: ghcr.io/mdusher/restic-backup-docker:latest
    hostname: nas                                     # This will be visible in restic snapshot list
    restart: always
    privileged: true
    volumes:
      - /volume1/Backup:/data/Backup:ro               # Backup /volume1/Backup from host
      - /home/user:/data/home:ro                      # Backup /home/user from host
      - ./post-backup.sh:/hooks/post-backup.sh:ro     # Run script post-backup.sh after every backup
      - ./post-check.sh:/hooks/post-check.sh:ro       # Run script post-check.sh after every check
      - ./ssh:/root/.ssh                              # SSH keys and config so we can login to "storageserver" without password
    environment:
      - RESTIC_REPOSITORY=sftp:storageserver:/storage/nas  # Backup to server "storageserver" 
      - RESTIC_PASSWORD=passwordForRestic                  # Password restic uses for encryption
      - BACKUP_CRON=0 22 * * 0                             # Start backup every Sunday 22:00 UTC
      - CHECK_CRON=0 22 * * 3                              # Start check every Wednesday 22:00 UTC
      - RESTIC_DATA_SUBSET=50G                             # Download 50G of data from "storageserver" every Wednesday 22:00 UTC and check the data integrity
      - RESTIC_FORGET_ARGS=--prune --keep-last 12          # Only keep the last 12 snapshots
```
