# Docker Phase 5

Phase 5 starts the final runtime track after the Rails 7.2 baseline is stable.
The conservative candidate is Ubuntu 26.04, Ruby 3.3, and Rails 7.2.x.

## Ubuntu 26.04 / Ruby 3.3 Candidate

- `app-ubuntu26-ruby33` builds Ruby 3.3.11 on Ubuntu 26.04.
- Bundler is raised to 2.5.23 for the Ruby 3.3 candidate image.
- The app still uses Rails 7.2.x and the Phase 4 MySQL / Greenmail services.
- The direct Rails endpoint is `http://localhost:3008/`.
- The Phase 5 Nginx proxy endpoint is `http://localhost:3009/`.
- The Phase 5 service has separate bundle, log, asset, tmp, and upload volumes
  so it can be tested without disturbing the Phase 4 Ubuntu 22.04 runtime.
- Phase 5 mounts `Gemfile.phase5.lock` as `Gemfile.lock` so Ruby 3.3 can use
  gems that no longer support the Phase 4 Ruby 3.1 runtime.
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
- `nkf` is now an explicit bundle dependency so the mail and CSV encoding
  paths do not rely on Ruby's stdlib-default copy.
- Ruby 3.3.11 is built with `--enable-yjit`. The `cargo` package provides the
  Rust compiler so ruby-build can compile the YJIT backend.
- `Rails.application.config.yjit` is enabled conditionally in
  `config/initializers/new_framework_defaults_7_2.rb` only when
  `RUBY_VERSION >= "3.3"` and `RubyVM::YJIT` is defined, so Phase 3/4
  containers running Ruby 3.1 are unaffected.
- The Phase 5 lock raises `nokogiri` to `1.19.x` to resolve three known CVEs
  (GHSA-c4rq-3m3g-8wgx High, GHSA-v2fc-qm4h-8hqv Medium, GHSA-wx95-c6cv-8532
  Medium). The shared Phase 3/4 lock remains on `nokogiri 1.18.10` because
  `nokogiri 1.19.x` requires Ruby 3.2+.
- The Phase 5 lock raises `brakeman` to `8.0.4` so the scanner runs on Ruby 3.3
  without parser errors. The shared Phase 3/4 lock stays on `brakeman 7.1.1`
  for Ruby 3.1 compatibility.
- Brakeman reports six Weak/Medium findings; all are pre-existing patterns in
  the application code, not new issues from the migration. The Phase 5 security
  gate allows those known warnings while keeping parser errors and
  `bundler-audit` vulnerabilities as failures.
- `bundler-audit` was added as an explicit development dependency.
- The direct Ubuntu 26.04 / Ruby 3.3 runtime now builds, boots Rails, runs the
  test suite, and precompiles assets.
- `webmail:cleanup` passes (exit 0, silent success as designed).

Verification:

```sh
bin/docker-phase5 ubuntu26-build
bin/docker-phase5 ubuntu26-check
bin/docker-phase5 ubuntu26-yjit-check
bin/docker-phase5 ubuntu26-test
bin/docker-phase5 ubuntu26-assets
bin/docker-phase5 ubuntu26-up
bin/docker-phase5 ubuntu26-stack
bin/docker-phase5 ubuntu26-security
```

As of this phase checkpoint the direct app runtime, YJIT, asset, cleanup, and
security gates pass.

The Phase 5 profile includes app, proxy, worker, and scheduler services to
match the Phase 4 process layout. Use `ubuntu26-stack` to boot that full set
with the proxy on `http://localhost:3009/`.
