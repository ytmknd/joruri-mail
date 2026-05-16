# Docker Phase 3

Phase 3 starts by changing only the operating system base image. Ruby, Rails,
Bundler, database, and mail services stay aligned with the verified Phase 2
Ruby 2.7 baseline.

## Ubuntu 20.04 / Ruby 2.7 Verification

Build and boot-check the Ubuntu 20.04 app service:

```sh
bin/docker-phase3 ubuntu20-build
bin/docker-phase3 ubuntu20-check
```

Run the phase gate checks against `app-ubuntu20-ruby27`:

```sh
docker compose --profile phase3 run --rm app-ubuntu20-ruby27 bundle exec rake assets:precompile
docker compose --profile phase3 run --rm app-ubuntu20-ruby27 bundle exec rake db:schema:load
docker compose --profile phase3 run --rm app-ubuntu20-ruby27 bundle exec rake db:seed
docker compose --profile phase3 run --rm app-ubuntu20-ruby27 bundle exec rake db:seed:demo
```

Then start the app on port `3004`:

```sh
bin/docker-phase3 ubuntu20-up
```

Keep this step scoped to Ubuntu 20.04. Do not raise Ruby or Rails in the same
diff.

Ubuntu 20.04 raises native library versions while Ruby and Rails stay fixed.
The first compatibility updates in this phase are:

- `charlock_holmes` `0.7.9`, for ICU 66.
- `mysql2` `0.5.7`, for the Ubuntu 20.04 MariaDB client library.
