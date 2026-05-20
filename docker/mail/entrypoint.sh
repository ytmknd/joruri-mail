#!/bin/bash
set -euo pipefail

# Create vmail group/user for virtual mailbox ownership
if ! getent group vmail > /dev/null 2>&1; then
  groupadd --gid 5000 vmail
fi
if ! getent passwd vmail > /dev/null 2>&1; then
  useradd --uid 5000 --gid 5000 --no-create-home --shell /usr/sbin/nologin vmail
fi

# Create mailbox directories for all users
VHOSTS_BASE=/var/mail/vhosts/localhost.localdomain.jp
for user in admin user1 user2 user3; do
  maildir="$VHOSTS_BASE/$user/Maildir"
  mkdir -p "$maildir/cur" "$maildir/new" "$maildir/tmp"
done
chown -R vmail:vmail /var/mail/vhosts

# Postfix setup
postmap /etc/postfix/virtual_mailbox_maps
postmap /etc/postfix/virtual_alias_maps
newaliases

# Fix Postfix spool permissions
chown -R postfix:postfix /var/spool/postfix/private 2>/dev/null || true

echo "Starting Postfix + Dovecot mail server..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/mail.conf
