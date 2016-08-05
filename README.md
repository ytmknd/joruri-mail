# Joruri Mail

Japan Originated Ruby-based RESTful and Integrated Mail

Joruri Mail is a browser-based IMAP client software.

Features:
* Simple and intuitive UI
* User customizable settings (filters, templates, signatures, labels and more)
* Multilingual mail decoding (especially japanese proper decoding)
* Drag and drop features (local files, mails and mailboxes)
* Secure structure due to not saving email body in application database
* Optimized UI for feature phone and smartphone
* Cooperation with [Joruri Gw](https://github.com/joruri/joruri-gw) (single sign-on, schedule registration)

## Demo

[http://joruri.org/demo/jorurimail/](http://joruri.org/demo/jorurimail/)

## System dependencies

* OS: CentOS 7.2 x86_64 (recommended), CentOS 6.8 x86_64
* Web server: Apache 2.4 (recommended), Apache 2.2
* DB server: MySQL 5.6
* Ruby: 2.3
* Rails: 4.2
* Mail server: SMTP, IMAP4

## Installation

Installation maunal assumes:

* CentOS is installed as minimal cofiguration
* SELinux is diabled
* Firewall is disabled

Make sure your enviroment is secure.

### Quick install

Execute script below as root user:

    export LANG=ja_JP.UTF-8; curl -L https://raw.githubusercontent.com/joruri/joruri-mail/master/doc/install_scripts/prepare.sh | bash

### Manual install

[doc/INSTALL.txt](doc/INSTALL.txt)

## Supported IMAP servers

IMAP servers with following capabilities are supported:

* IMAP4REV1: [RFC2060](https://www.ietf.org/rfc/rfc2060.txt), [RFC3501](https://www.ietf.org/rfc/rfc3501.txt)
* SORT: [RFC5256](https://www.ietf.org/rfc/rfc5256.txt)
* QUOTA: [RFC2087](https://www.ietf.org/rfc/rfc2087.txt) (recommended)
* LIST-STATUS: [RFC5819](https://www.ietf.org/rfc/rfc5819.txt) (recommended)
* MOVE: [RFC6851](https://www.ietf.org/rfc/rfc6851.txt) (recommended)
* ESORT: [RFC5267](https://www.ietf.org/rfc/rfc5267.txt) (recommended)

## Changelog

[doc/CHANGES.txt](doc/CHANGES.txt)

## DB Changelog

[doc/DB_CHANGES.txt](doc/DB_CHANGES.txt)

## License

GNU GENERAL PUBLIC LICENSE Version 3

[LICENSE](LICENSE)

Copyright (C) Tokushima Prefectural Government, IDS Inc., SiteBridge Inc.

[COPYING](COPYING)
