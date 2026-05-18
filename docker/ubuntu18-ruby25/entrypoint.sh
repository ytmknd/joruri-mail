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
      vendor/bundle
  fi
  exec gosu joruri "$0" "$@"
fi

if [[ "${1:-}" = "bundle" && "${2:-}" = "exec" && "${3:-}" = "rails" && "${4:-}" = "server" ]]; then
  rm -f tmp/pids/server.pid
fi

git config --global url."https://github.com/".insteadOf git://github.com/

bundle_version="${BUNDLER_VERSION:-1.17.3}"
if ! bundle _"${bundle_version}"_ check > /dev/null 2>&1; then
  bundle _"${bundle_version}"_ install --path vendor/bundle
fi

exec "$@"
