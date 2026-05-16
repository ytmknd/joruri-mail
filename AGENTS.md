# Codex Project Notes

## Migration Strategy

This project is being migrated toward an Ubuntu 26.04 container runtime.

Do not jump directly to Ubuntu 26.04. First create a reproducible legacy container environment, then raise Ubuntu, Ruby, and Rails one step at a time. Every step must pass the agreed verification checks before moving to the next step.

Ruby 2.3 is end-of-life and must be treated only as a temporary migration baseline. The Ubuntu 18.04 environment exists to reproduce the current application, not as a final runtime.

## Phase 0: Pin Current Behavior And Verification Base

Prepare Docker Compose around the current application shape.

Target services over the full phase:

- `app`: Ubuntu 18.04 + Ruby 2.3.x + Bundler 1.11.2 + Rails 5.0.0.1
- `db`: MySQL 5.6, or MySQL 5.7 for early verification if 5.6 is impractical
- `smtp` / `imap`: GreenMail or equivalent test mail service
- optional `ldap`: OpenLDAP test container

Initial Docker work should start with only the application container. Do not add database or IMAP containers until the Rails app container can build and boot.

Phase 0 completion criteria:

- `bundle install`
- `db:schema:load`
- `db:seed`
- `assets:precompile`
- Rails server boot
- admin login
- SMTP/IMAP connection checks
- `delayed_job`
- `whenever` equivalent scheduled tasks

## Phase 1: Reproduce On Ubuntu 18.04 + Ruby 2 + Rails 5

Use Ruby 2.3.x for the first reproducible container.

Preferred default:

- Ruby 2.3.8 for migration stability
- Ruby 2.3.1 only when strict historical reproduction is required

Ruby 2.3 may require OpenSSL 1.0.x. If needed, include OpenSSL 1.0.x only as a build/runtime compatibility aid for this phase. Do not carry this OpenSSL approach into the final runtime.

## Phase 2: Stabilize Within Rails 5

Before large OS jumps, clean up application dependencies and move safely within Rails 5.

Recommended order:

1. Rails 5.0.0.1 to the latest Rails 5.0 patch.
2. Ruby 2.3 to Ruby 2.4 / 2.5.
3. Rails 5.1.
4. Rails 5.2.
5. Ruby 2.6 / 2.7.

Dependencies that need special attention:

- `activerecord-session_store`: current locked dependency constrains Rails below 5.1.
- `delayed_job_active_record`: update for Rails 5.1+.
- `therubyracer` / `libv8`: replace with Node.js or `mini_racer`.
- `rmagick`: update for newer ImageMagick.
- `ruby-ldap`: consider migration to `net-ldap`.
- `hpricot`: deprecated; prefer Nokogiri.
- `zipruby`: consider migration to `rubyzip`.
- `nokogiri` / `nokogumbo` / `sanitize`: update as a coordinated set.
- `bower-rails`: keep fixed first, then migrate to npm/yarn or static `vendor/assets`.

## Phase 3: Raise Ubuntu Gradually

Do not raise the OS too far ahead of Ruby and native gem compatibility. OpenSSL and native extensions are expected risks.

| Step | Ubuntu | Ruby | Rails | Purpose |
|---|---:|---:|---:|---|
| A | 18.04 | 2.3.x | 5.0.x | Reproduce current app |
| B | 18.04 / 20.04 | 2.5 / 2.6 | 5.2.x | Stabilize Rails 5 |
| C | 20.04 | 2.7.x | 6.0 / 6.1 | Prepare before Ruby 3 |
| D | 22.04 | 3.1.x | 6.1 / 7.0 | Start OpenSSL 3 era compatibility |
| E | 24.04 | 3.2 / 3.3 | 7.1 / 7.2 | Move toward current Rails |
| F | 26.04 | 3.3 / 3.4 / 4.0 | 7.2+ | Final runtime candidate |

Rails 7.2 requires Ruby 3.1 or newer. Treat Rails 7.2 as the practical first long-term milestone. Rails 8 can be a separate phase after Rails 7.2 is stable.

## Phase 4: Rails 6 And Rails 7 Migration

Move Rails by minor versions. Keep each diff small and verifiable.

- Run `rails app:update` at each Rails step and review the generated diff carefully.
- Do not switch `config.load_defaults` all the way to the newest version at once.
- Verify Zeitwerk compatibility in Rails 6.
- Remove `secrets.yml` dependency over time; prefer environment variables or credentials for final runtime.
- Migrate Bower assets to npm/yarn or static `vendor/assets`.
- Move from Passenger/Apache assumptions to Puma plus a reverse proxy in containers.
- Run `delayed_job` as a separate process from the web server.
- Do not rely on in-container cron for final operation; use a scheduler container or external job runner.

## Phase 5: Ubuntu 26.04 Finalization

Final runtime candidates:

- Conservative: Ubuntu 26.04 + Ruby 3.3/3.4 + Rails 7.2.x
- Current-track: Ubuntu 26.04 + Ruby 4.0 + Rails 8.1.x

Prefer reaching and stabilizing Rails 7.2 first. Evaluate Rails 8 only after that baseline is healthy.

## Verification Gate For Every Step

Do not proceed to the next migration step until these checks pass:

- `bundle install`
- `rails runner 'puts Rails.version'`
- `db:create db:schema:load db:seed`
- `assets:precompile`
- Rails server boot
- admin login
- mail list display
- SMTP send
- IMAP move/delete/search
- attachment handling
- Japanese mail and ISO-2022-JP display
- `delayed_job` execution
- `webmail:cleanup`
- Brakeman and bundle-audit equivalent security checks

## Docker Development Rules

When preparing Docker-related files, use `doc/INSTALL.txt` as the primary reference for the legacy installation procedure and system package requirements.

Use `bin/docker-phase1` as the project-local command wrapper for the phase 0/1 Docker workflow:

- `bin/docker-phase1 build`: runs `docker compose build app`.
- `bin/docker-phase1 check`: runs `docker compose run --rm app ruby -v` and `docker compose run --rm app bundle exec rails runner 'puts "Rails #{Rails.version} booted"'`.
- `bin/docker-phase1 up`: runs `docker compose up app`.
- `bin/docker-phase1 all`: runs build, check, then starts the app.

Use `bin/docker-phase2` for Rails 5 upgrade work. It targets the `app-phase2` Compose service, keeps Ruby 2.3.8 for the first Rails 5.0 patch update, keeps separate bundle/log/tmp/assets volumes from phase 0/1, and exposes the Rails server on `http://localhost:3001/`.

- `bin/docker-phase2 build`: runs `docker compose build app-phase2`.
- `bin/docker-phase2 check`: runs Ruby version and Rails boot checks in `app-phase2`.
- `bin/docker-phase2 up`: runs `docker compose up app-phase2`.
- `bin/docker-phase2 bundle-update-rails50`: runs a conservative Rails lockfile update in `app-phase2`.

Use the `app-ruby25` Compose service, behind the `ruby-upgrade` profile, only after the Rails 5.0 patch update is stable and `therubyracer` has been removed or replaced.

The current project root directory on the host should be mounted into the container at `/var/share/jorurimail`. The source tree should remain editable from the host with Codex. Avoid writing large generated trees into the host checkout.

Gems, logs, temporary files, compiled assets, uploads, and similar generated folders should live on the container side as Docker named volumes. Do not let those paths create many files in the host-shared source tree.

Container-side generated paths must include Docker named volumes for:

- `/var/share/jorurimail/vendor/bundle`
- `/var/share/jorurimail/.bundle`
- `/var/share/jorurimail/log`
- `/var/share/jorurimail/tmp`
- `/var/share/jorurimail/public/assets`
- `/var/share/jorurimail/upload`
- `/var/share/jorurimail/vendor/assets/bower_components`

The application container must create and run as:

- user: `joruri`
- uid: `1000`
- gid: `1000`

Ensure `/var/share/jorurimail` and container-side writable paths are readable and writable by `joruri`. Read-only mounted configuration files may be skipped by ownership-fix logic.

For phase 0/1, database and IMAP containers should not be introduced until the app container can build and Rails can boot.
