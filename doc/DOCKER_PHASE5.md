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
- The build currently stops during `bundle install` on legacy native gems:
  `byebug 9.0.5`, `rmagick 2.16.0`, `ruby-ldap 0.9.19`, and `zipruby 0.3.6`.
- The next Phase 5 step is to replace or upgrade those gems before treating
  Ubuntu 26.04 as a runnable app baseline.

Verification:

```sh
bin/docker-phase5 ubuntu26-build
bin/docker-phase5 ubuntu26-check
bin/docker-phase5 ubuntu26-test
bin/docker-phase5 ubuntu26-assets
```

The `ubuntu26-check`, `ubuntu26-test`, and `ubuntu26-assets` gates are blocked
until the native gem compatibility work above is complete.

After the direct app runtime is healthy, add the Phase 5 proxy, worker, and
scheduler services to match the Phase 4 process layout.
