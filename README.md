# Joruri Mail

Japan Originated Ruby-based RESTful and Integrated Mail

Joruri Mail is a browser-based IMAP client software.

## Features

* Simple and intuitive UI
* User customizable settings (filters, templates, signatures, labels and more)
* Multilingual mail decoding (especially japanese proper decoding)
* Drag and drop features (local files, mails and mailboxes)
* Secure structure due to not saving email body in application database
* Optimized UI for feature phone and smartphone
* Cooperation with [Joruri Gw](https://github.com/joruri/joruri-gw) (single sign-on, schedule registration)

## System requirements

* Ubuntu 26.04
* Ruby 4.0
* Rails 8.1
* MySQL 5.7
* SMTP, IMAP4

Container-based development and deployment is the recommended approach.
See [doc/PODMAN.md](doc/PODMAN.md) for Podman setup (AlmaLinux 9 / macOS).

## Quick start (Docker / Podman)

```sh
# Build the application image (linux/amd64)
bin/phase5 ubuntu26-build

# Verify Ruby + Rails + YJIT boot correctly
bin/phase5 ubuntu26-check

# Start the Rails server at http://localhost:3008/
bin/phase5 ubuntu26-up

# Run the test suite
bin/phase5 ubuntu26-test
```

`bin/phase5` auto-detects Podman or Docker and applies the correct flags for
each runtime. On SELinux-enforcing hosts (AlmaLinux 9), the SELinux override is
applied automatically.

Force a specific runtime:

```sh
PHASE5_RUNTIME=podman bin/phase5 ubuntu26-check
PHASE5_RUNTIME=docker bin/phase5 ubuntu26-check
# or via the wrapper scripts:
bin/podman-phase5 ubuntu26-check
bin/docker-phase5 ubuntu26-check
```

For manual installation instructions see [doc/INSTALL.txt](doc/INSTALL.txt).

## IMAP capabilities

Following IMAP capabilities are supported:

* IMAP4REV1: [RFC2060](https://tools.ietf.org/html/rfc2060), [RFC3501](https://tools.ietf.org/html/rfc3501) (required)
* SORT: [RFC5256](https://tools.ietf.org/html/rfc5256) (recommended)
* QUOTA: [RFC2087](https://tools.ietf.org/html/rfc2087) (recommended)
* LIST-STATUS: [RFC5819](https://tools.ietf.org/html/rfc5819) (recommended)
* MOVE: [RFC6851](https://tools.ietf.org/html/rfc6851) (recommended)
* ESORT: [RFC5267](https://tools.ietf.org/html/rfc5267) (recommended)
* SPECIAL-USE: [RFC6154](https://tools.ietf.org/html/rfc6154) (not required)

## SMTP extensions

Following SMTP extensions are supported:

* Delivery Status Notification: [RFC3461](https://tools.ietf.org/html/rfc3461)

## Changelog

[doc/CHANGES.txt](doc/CHANGES.txt)

## DB Changelog

[doc/DB_CHANGES.txt](doc/DB_CHANGES.txt)

## License

GNU GENERAL PUBLIC LICENSE Version 3

[LICENSE](LICENSE)

Copyright (C) Tokushima Prefectural Government, IDS Inc., SiteBridge Inc.

[COPYING](COPYING)
