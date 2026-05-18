# Docker Phase 5

Phase 5 starts the final runtime track after the Rails 7.2 baseline is stable.
The conservative candidate is Ubuntu 26.04, Ruby 3.3, and Rails 7.2.x.

## Ubuntu 26.04 / Ruby 3.3 Candidate

- `app-ubuntu26-ruby33` builds Ruby 3.3.11 on Ubuntu 26.04.
- Bundler is raised to 2.5.23 for the Ruby 3.3 candidate image.
- The app still uses Rails 7.2.x and the Phase 4 MySQL / Greenmail services.
- The direct Rails endpoint is `http://localhost:3008/`.
- The Phase 5 service has separate bundle, log, asset, tmp, and upload volumes
  so it can be tested without disturbing the Phase 4 Ubuntu 22.04 runtime.
- Ubuntu 26.04 already includes a UID/GID 1000 user/group in the base image, so
  the Dockerfile renames the existing account to `joruri` when needed instead
  of assuming `groupadd --gid 1000` will succeed.

Current build status:

- `docker compose build app-ubuntu26-ruby33` reaches Ruby 3.3.11 and Bundler
  2.5.23 successfully.
- `byebug 9.0.5`, `hpricot 0.8.6`, `zipruby 0.3.6`, and the legacy
  development watcher stack were removed or replaced; the Phase 4 test suite
  still passes with the replacement dependencies.
- `ffi` was raised to `1.17.x` so native gems can build on the Ruby 3.3
  candidate image.
- `sanitize` was raised to `6.1.x`, which removes the `nokogumbo 2.0.5`
  native extension from the bundle.
- `rmagick` was raised to `6.3.x`, which builds against the Ubuntu 26.04
  ImageMagick headers.
- `ruby-ldap 0.9.19` was replaced with `net-ldap 0.20.x` so the LDAP wrapper
  no longer depends on the removed Ruby C API.
- `premailer` was raised to `1.27.x`, pulling in a Ruby 3.3-compatible
  `css_parser`.
- The direct Ubuntu 26.04 / Ruby 3.3 runtime now builds, boots Rails, runs the
  test suite, and precompiles assets.

Verification:

```sh
bin/docker-phase5 ubuntu26-build
bin/docker-phase5 ubuntu26-check
bin/docker-phase5 ubuntu26-test
bin/docker-phase5 ubuntu26-assets
```

As of this phase checkpoint all four direct app runtime gates pass.

After the direct app runtime is healthy, add the Phase 5 proxy, worker, and
scheduler services to match the Phase 4 process layout.
