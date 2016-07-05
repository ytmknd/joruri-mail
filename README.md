# Joruri Mail

Joruri Mail (Japan Originated Ruby-based RESTful and Integrated Mail) is a web mail software, communicates with imap and smtp server.

Features:
* Simple and intuitive UI
* User customizable settings (filters, templates, signs, labels and more)
* Multilingual mail (especially japanese proper decoding)
* Drag and drop file attachment
* Request for mail delivery receipt
* Optimized UI for feature phone and smartphone
* Cooperation with Joruri Gw (single sign-on, schedule registration)

Supported imap servers:
* dovecot
* imap servers with following capabilities: IMAP4REV1, SORT, QUOTA

## Demo

<a href="http://joruri.org/demo/jorurimail/" target="_blank">http://joruri.org/demo/jorurimail/</a>

## Quick install

    export LANG=ja_JP.UTF-8; curl -L https://raw.githubusercontent.com/joruri/joruri-mail/master/doc/install_scripts/prepare.sh | bash

## Manual install

[doc/INSTALL.md](doc/INSTALL.md)

## Changelog

[doc/CHANGES.md](doc/CHANGES.md)

## DB Changelog

[doc/DB_CHANGES.md](doc/DB_CHANGES.md)

## License

GNU GENERAL PUBLIC LICENSE Version 3

[LICENCE](LICENCE)

Copyright (C) Tokushima Prefectural Government, IDS Inc., SiteBridge Inc.

[COPYING](COPYING)
