# Docker Phase 5

Phase 5 starts the final runtime track after the Rails 7.2 baseline is stable.
The conservative candidate is Ubuntu 26.04, Ruby 3.3, and Rails 7.2.x.
The current-track target is Ubuntu 26.04, Ruby 4.0, and Rails 8.1.x.

## Ubuntu 26.04 / Ruby 3.3 Conservative Track (complete)

The conservative track reached Ubuntu 26.04 + Ruby 3.3.11 + Rails 7.2.x and
then graduated through Rails 8.1 before the Ruby 4.0 upgrade.

Key milestones:
- `config.load_defaults 7.2` graduated; `new_framework_defaults_7_x.rb` removed.
- Rails upgraded to 8.1.3; `config.load_defaults 8.1` graduated.
- All Rails 8.1 framework defaults verified and the defaults file removed.
- Multi-action route syntax (`get :a, :b, :c`) split to individual declarations
  for Rails 8 compatibility.

## Ubuntu 26.04 / Ruby 4.0 Current Track

- `app-ubuntu26-ruby4` builds Ruby 4.0.4 on Ubuntu 26.04.
- Bundler stays at 2.5.23 for the Ruby 4.0 image.
- The app runs Rails 8.1.x, `config.load_defaults 8.1`.
- The direct Rails endpoint is `http://localhost:3008/`.
- The Phase 5 Nginx proxy endpoint is `http://localhost:3009/`.
- Phase 5 mounts `Gemfile.phase5.lock` as `Gemfile.lock` so Ruby 4.0 can use
  gems that no longer support the Phase 4 Ruby 3.1 runtime.
- Separate bundle, log, asset, tmp, and upload volumes (`*_ubuntu26_ruby4`)
  isolate Phase 5 from earlier phases.
- Ubuntu 26.04 already includes a UID/GID 1000 user/group in the base image;
  the Dockerfile renames the existing account to `joruri` when needed.

Build status:

- `docker/ubuntu26-ruby4/Dockerfile` builds Ruby 4.0.4 with `--enable-yjit`
  (Rust/cargo provides the YJIT backend at build time).
- `config/initializers/yjit.rb` enables `config.yjit` when Ruby >= 3.3 and
  `RubyVM::YJIT` is defined; Phase 3/4 containers on Ruby 3.1 are unaffected.
- `nokogiri 1.19.x` in the Phase 5 lock resolves three known CVEs.
- `brakeman 8.0.4` in the Phase 5 lock runs without parser errors on Ruby 4.0.
- `bundler-audit`: no vulnerabilities found.
- Brakeman: six Weak/Medium findings, all pre-existing patterns in application
  code.

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

The Phase 5 profile includes app, proxy, worker, and scheduler services to
match the Phase 4 process layout. Use `ubuntu26-stack` to boot that full set
with the proxy on `http://localhost:3009/`.
