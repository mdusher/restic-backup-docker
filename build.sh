#!/bin/sh

VERSION_TAG=v1.4.0

docker build -t ghcr.io/mdusher/restic-backup-docker:latest .
docker tag ghcr.io/mdusher/restic-backup-docker:latest quay.io/mdusher/restic-backup-docker:${VERSION_TAG}