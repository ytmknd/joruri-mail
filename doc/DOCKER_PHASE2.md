# Docker phase 2

Phase 2 is for raising Rails inside the Rails 5 line before larger OS jumps.

This keeps the phase 0/1 `app` service intact and adds `app-phase2`:

- Ubuntu 18.04
- Ruby 2.3.8
- Bundler 1.11.2
- Rails from the working tree `Gemfile` / `Gemfile.lock`
- Separate Docker named volumes from phase 0/1
- Host port `3001`

The initial Rails upgrade target is the latest Rails 5.0.x patch while keeping Ruby 2.3.8. After that, move to Ruby 2.4/2.5, then Rails 5.1 and Rails 5.2 in separate code commits.

The `app-ruby25` service and `docker/ubuntu18-ruby25/Dockerfile` are provided for the Ruby 2.5 verification step. That service is behind the `ruby-upgrade` Compose profile. ExecJS uses Node.js from the Docker image; `therubyracer` and `libv8` are no longer part of the bundle.

## Commands

Build:

```sh
bin/docker-phase2 build
```

Check Ruby and Rails boot:

```sh
bin/docker-phase2 check
```

Start the app:

```sh
bin/docker-phase2 up
```

Open:

```text
http://localhost:3001/
```

## First Rails 5.0 Patch Update

After adjusting `Gemfile` to allow Rails 5.0 patch updates, update the lockfile with:

```sh
bin/docker-phase2 bundle-update-rails50
```

Then run:

```sh
bin/docker-phase2 check
docker compose run --rm app-phase2 bundle exec rake db:schema:load
docker compose run --rm app-phase2 bundle exec rake db:seed
docker compose run --rm app-phase2 bundle exec rake db:seed:demo
```

## Ruby 2.5 Verification

Build and boot-check the Ruby 2.5 service with:

```sh
bin/docker-phase2 ruby25-build
bin/docker-phase2 ruby25-check
```

Run the phase gate checks against `app-ruby25`:

```sh
docker compose --profile ruby-upgrade run --rm app-ruby25 bundle exec rake bower:install
docker compose --profile ruby-upgrade run --rm app-ruby25 bundle exec rake assets:precompile
docker compose --profile ruby-upgrade run --rm app-ruby25 bundle exec rake db:schema:load
docker compose --profile ruby-upgrade run --rm app-ruby25 bundle exec rake db:seed
docker compose --profile ruby-upgrade run --rm app-ruby25 bundle exec rake db:seed:demo
```

Then start the app on port `3002`:

```sh
bin/docker-phase2 ruby25-up
```

The Ruby 2.5 lockfile uses Bundler 1.17.3 and updates `delayed_job` / `delayed_job_active_record` so Rails can boot without the old `yaml_as` compatibility error.

## Rails 5.1 Update

After Ruby 2.5 is stable, update Rails and the Rails 5.1 dependency blockers with:

```sh
bin/docker-phase2 bundle-update-rails51
```

The Rails 5.1 update raises:

- `rails` to `5.1.7`
- `activerecord-session_store` to `1.1.3`
- `jbuilder` to a Rails 5.1-compatible 2.x release

Then run the Ruby 2.5 gate checks again:

```sh
bin/docker-phase2 ruby25-check
docker compose --profile ruby-upgrade run --rm app-ruby25 bundle exec rake assets:precompile
docker compose --profile ruby-upgrade run --rm app-ruby25 bundle exec rake db:schema:load
docker compose --profile ruby-upgrade run --rm app-ruby25 bundle exec rake db:seed
docker compose --profile ruby-upgrade run --rm app-ruby25 bundle exec rake db:seed:demo
```

Rails 5.1 is stricter about named connection pools. Optional named connections such as `joruri_manage`, `dev_jgw_core`, and `session` should only call `establish_connection` when the matching database configuration exists.

## Rails 5.2 Update

After Rails 5.1 is stable, update Rails and the Rails 5.2 dependency blockers with:

```sh
bin/docker-phase2 bundle-update-rails52
```

The Rails 5.2 update raises:

- `rails` to `5.2.8.1`
- `coffee-rails` to `4.2.2`

Then run the Ruby 2.5 gate checks again:

```sh
bin/docker-phase2 ruby25-check
docker compose --profile ruby-upgrade run --rm app-ruby25 bundle exec rake assets:precompile
docker compose --profile ruby-upgrade run --rm app-ruby25 bundle exec rake db:schema:load
docker compose --profile ruby-upgrade run --rm app-ruby25 bundle exec rake db:seed
docker compose --profile ruby-upgrade run --rm app-ruby25 bundle exec rake db:seed:demo
```

Rails 5.2 removes `ActiveSupport.halt_callback_chains_on_return_false=` and rejects string callback/validation conditions. Keep the legacy default initializer guarded and use symbol, proc, lambda, or block conditions.

## Ruby 2.7 Verification

After Rails 5.2 is stable, verify the app on Ruby 2.7 with:

```sh
bin/docker-phase2 ruby27-build
bin/docker-phase2 ruby27-check
```

Run the phase gate checks against `app-ruby27`:

```sh
docker compose --profile ruby-upgrade run --rm app-ruby27 bundle exec rake assets:precompile
docker compose --profile ruby-upgrade run --rm app-ruby27 bundle exec rake db:schema:load
docker compose --profile ruby-upgrade run --rm app-ruby27 bundle exec rake db:seed
docker compose --profile ruby-upgrade run --rm app-ruby27 bundle exec rake db:seed:demo
```

Then start the app on port `3003`:

```sh
bin/docker-phase2 ruby27-up
```

The Ruby 2.7 service keeps Ubuntu 18.04 and Bundler 1.17.3 for this migration step, but switches to Ubuntu's OpenSSL 1.1 development package instead of the Ruby 2.3/2.5 OpenSSL 1.0 compatibility package.

## Notes

Use `app` for the frozen phase 0/1 baseline and `app-phase2` for Rails/Ruby migration work. Do not share bundle volumes between them.

Use `app-ruby25` only after the Rails 5.0 patch update is stable and the Node.js ExecJS runtime has passed `assets:precompile`.
