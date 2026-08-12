#!/bin/sh

export AUTHENTIK_SECRET_KEY="$(cat /run/secrets/authentik_secret_key)"

exec dumb-init -- ak "$@"
