#!/bin/sh

VERSION_TAG=0.18.0

docker build -t quay.io/mdusher/restic-backup-docker:latest .
docker tag quay.io/mdusher/restic-backup-docker:latest quay.io/mdusher/restic-backup-docker:${VERSION_TAG}