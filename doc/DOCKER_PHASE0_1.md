# Docker phase 0/1

This is the first container verification step for running the Rails 5 application on Ubuntu 18.04 with Ruby 2.

The host repository is mounted at `/var/share/jorurimail`. Generated/heavy paths are mounted as Docker named volumes so the source tree does not get filled with gems, logs, compiled assets, temporary files, or uploads.

At this stage the application, MySQL, and GreenMail containers are provided. LDAP is intentionally not included yet.

The container creates and runs the app as `joruri` with `uid=1000` and `gid=1000`. The entrypoint fixes ownership of `/var/share/jorurimail` before dropping privileges. Read-only mounted `config/*.yml` files are skipped. To disable source-tree ownership fixes, set `CHOWN_SOURCE_TREE=0`.

## Build

```sh
docker compose build app
```

The image uses:

- Ubuntu 18.04
- Ruby 2.3.8 via rbenv
- Bundler 1.11.2
- Rails 5.0.0.1 from the existing Gemfile
- Native packages based on `doc/INSTALL.txt`

## Services

- `app`: Rails application on `http://localhost:3000/`
- `db`: MySQL 5.7 with `jorurimail` and `jorurimail_test`
- `imap`: GreenMail test mail server

GreenMail uses test ports with an offset of 3000:

- SMTP: `imap:3025`, exposed on host port `3025`
- IMAP: `imap:3143`, exposed on host port `3143`
- API: `http://localhost:8081/`

Seeded GreenMail users:

- `admin` / `admin`
- `user1` / `user1`
- `user2` / `user2`
- `user3` / `user3`

## Boot checks

Check Ruby and Rails versions:

```sh
docker compose run --rm app ruby -v
docker compose run --rm app bundle exec rails runner 'puts "Rails #{Rails.version} booted"'
```

Start the Rails server:

```sh
docker compose up app
```

Start only MySQL and GreenMail:

```sh
docker compose up -d db imap
```

Check IMAP login from the app container:

```sh
docker compose run --rm app ruby -rnet/imap -e 'imap = Net::IMAP.new("imap", 3143); imap.login("user1", "user1"); puts imap.capability.inspect; imap.logout'
```

Open:

```text
http://localhost:3000/
```

If the database volume is empty, initialize the schema and demo data before browser verification:

```sh
docker compose run --rm app bundle exec rake db:schema:load
docker compose run --rm app bundle exec rake db:seed
docker compose run --rm app bundle exec rake db:seed:demo
```

For phase 0/1, the success condition is that the container builds, Bundler resolves, Rails boots, the server listens on port 3000, and the app can connect to MySQL and GreenMail.

## Optional asset setup

Bower output is stored in a named volume at `vendor/assets/bower_components`.

```sh
docker compose run --rm app bundle exec rake bower:install
```

## Reset generated container data

This removes container-side gems/logs/tmp/assets/uploads for this Compose project.

```sh
docker compose down -v
```
