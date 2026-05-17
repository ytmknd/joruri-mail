# Docker Phase 4

Phase 4 starts while the runtime is still Ubuntu 20.04, Ruby 2.7, and Rails
6.1. Keep this phase focused on Rails 6 and Rails 7 migration work before
moving to Ruby 3 or Ubuntu 22.04.

## Rails 6.1 Zeitwerk Baseline

The first Phase 4 baseline enables Zeitwerk without changing Rails defaults to a
newer version all at once.

- `config.autoloader = :zeitwerk` is enabled in `config/application.rb`.
- `lib/plugins` remains manually required by the Joruri initializer and is
  ignored by Zeitwerk because it contains monkey patches, not conventionally
  named application constants.
- `config/storage.yml` is present so Rails 6.1 can eager load Active Storage
  railties even though the application does not use Active Storage tables yet.
- `System::Database` uses the Rails 6.1 `ActiveRecord::DatabaseConfigurations`
  API before conditionally connecting to `dev_jgw_core`.

Verification:

```sh
bin/docker-phase3 ubuntu20-check
docker compose --profile phase3 run --rm app-ubuntu20-ruby27 bundle exec rails zeitwerk:check
docker compose --profile phase3 run --rm app-ubuntu20-ruby27 bundle exec rake assets:precompile
bin/docker-phase3 ubuntu20-smoke
```

`rails app:update` has been audited in a temporary copy for Rails 6.1. The
remaining generated files, such as Active Storage migrations and new policy
initializers, are intentionally not applied in this baseline.
