# Changelog

## Unreleased

## v1.4.1 (restic 0.18.0)
* Use full base image names
* Refactor to mdusher's preferred script style
* Make crond the container's running process
* Modify entry.sh to forward output to crond's stdout
* Remove Teams hook
* Remove Openstack Swift support
* Removed "Not found" log message for pre and post backup scripts
* Made RESTIC_TAG optional
* Moved rclone architecture to a build argument in the Dockerfile
* Add validation for required environment variables to entry.sh
* Cleaned up readme

## v1.4.0 (restic 0.18.0)
* Updated to restic 0.18.0
* Lock `alpine` container image version to `3.21`
* Lock `rclone` version to `v1.69.1`
* Swapped mailx out for s-nail, mailx syntax has changed.

## v1.3.2 (restic 0.16.0)

### Changed
* Base image directly on official restic image
* [Semver](https://semver.org/) aligned version naming including restic version
* Updated to restic 0.16.0

### Added
* rclone to docker image
* Implemented a simple mail notification after backups using mailx
* MAILX_ARGS environment variable

## v1.3.1-0.9.6

### Changed
* Update to Restic v0.9.5
* Reduced the number of layers in the Docker image

### Fixed
* Check if a repo already exists works now for all repository types

### Added
* shh added to container
* fuse added to container
* support to send mails using external SMTP server after backups

## v1.2-0.9.4

### Added
* AWS Support

## v1.1

### Fixed
* `--prune` must be passed to `RESTIC_FORGET_ARGS` to execute prune after forget.

### Changed
* Switch to base Docker container to `golang:1.7-alpine` to support latest restic build.

## v1.0

Initial release.

The container has proper logs now and was running for over a month in production. 
There are still some features missing. Sticking to semantic versioning we do not expect any breaking changes in the 1.x releases.
