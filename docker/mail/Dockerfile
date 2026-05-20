FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      dovecot-core \
      dovecot-imapd \
      dovecot-lmtpd \
      netcat-openbsd \
      postfix \
      rsyslog \
      supervisor \
    && rm -rf /var/lib/apt/lists/*

# -------- Postfix --------
COPY docker/mail/postfix/main.cf  /etc/postfix/main.cf
COPY docker/mail/postfix/master.cf /etc/postfix/master.cf
COPY docker/mail/postfix/virtual_mailbox_maps /etc/postfix/virtual_mailbox_maps
COPY docker/mail/postfix/virtual_alias_maps   /etc/postfix/virtual_alias_maps

# -------- Dovecot --------
COPY docker/mail/dovecot/dovecot.conf /etc/dovecot/dovecot.conf
COPY docker/mail/dovecot/conf.d/      /etc/dovecot/conf.d/
COPY docker/mail/dovecot/users        /etc/dovecot/users

# -------- Supervisor --------
COPY docker/mail/supervisord.conf /etc/supervisor/conf.d/mail.conf

# -------- Entrypoint --------
COPY docker/mail/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3025 3143

ENTRYPOINT ["/entrypoint.sh"]
