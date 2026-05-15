#!/usr/bin/env bash
set -euo pipefail

cd /var/share/jorurimail

mkdir -p \
  .bundle \
  config \
  log \
  public/assets \
  tmp/cache \
  tmp/pids \
  tmp/sockets \
  upload \
  vendor/assets/bower_components \
  vendor/bundle

for source in docker/phase1/config/*.yml; do
  target="config/$(basename "${source}")"
  if [[ -f "${source}" && ! -s "${target}" ]]; then
    cp "${source}" "${target}"
  fi
done

if [[ "$(id -u)" = "0" ]]; then
  if [[ "${CHOWN_SOURCE_TREE:-1}" = "1" ]]; then
    find . \
      \( -path './.git' -o -path './config/*.yml' \) -prune -o \
      -exec chown -h joruri:joruri {} +
  else
    chown -R joruri:joruri \
      .bundle \
      log \
      public/assets \
      tmp \
      upload \
      vendor/assets/bower_components \
      vendor/bundle
  fi
  exec gosu joruri "$0" "$@"
fi

rm -f tmp/pids/server.pid

git config --global url."https://github.com/".insteadOf git://github.com/

if ! bundle check > /dev/null 2>&1; then
  bundle _1.11.2_ install --path vendor/bundle
fi

exec "$@"
