#!/bin/sh
set -e

export HOMEPAGE_VAR_PROXMOX_USERNAME="$(cat /run/secrets/homepage_proxmox_username)"
export HOMEPAGE_VAR_PROXMOX_PASSWORD="$(cat /run/secrets/homepage_proxmox_password)"

exec docker-entrypoint.sh "$@"
