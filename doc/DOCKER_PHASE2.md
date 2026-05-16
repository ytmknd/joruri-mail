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

The `app-ruby25` service and `docker/ubuntu18-ruby25/Dockerfile` are provided for the later Ruby 2.5 verification step. That service is behind the `ruby-upgrade` Compose profile. ExecJS uses Node.js from the Docker image; `therubyracer` and `libv8` are no longer part of the bundle.

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

## Notes

Use `app` for the frozen phase 0/1 baseline and `app-phase2` for Rails/Ruby migration work. Do not share bundle volumes between them.

Use `app-ruby25` only after the Rails 5.0 patch update is stable and the Node.js ExecJS runtime has passed `assets:precompile`.
