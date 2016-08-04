#!/bin/bash
DONE_FLAG="/tmp/$0_done"

echo '#### Install Joruri Mail ####'
if [ -f $DONE_FLAG ]; then exit; fi
echo '-- PRESS ENTER KEY --'
read KEY

ubuntu() {
  echo 'Ubuntu will be supported shortly.'
}

centos() {
  echo "It's CentOS!"

  if [ -d /var/share/jorurimail ]; then
    echo 'Joruri is already installed.'
    exit
  fi

  id joruri || useradd -m joruri

  yum install -y ImageMagick-devel libjpeg-devel libpng-devel librsvg2-devel
  yum install -y libxml2-devel libxslt-devel mysql-devel openldap-devel shared-mime-info libicu-devel npm
  npm install bower@1.7.9 -g

  git clone https://github.com/joruri/joruri-mail.git /var/share/jorurimail
  # git clone -b develop https://github.com/joruri/joruri-mail.git /var/share/jorurimail

  chown -R joruri:joruri /var/share/jorurimail
  su - joruri -c "cd /var/share/jorurimail && bundle install --path vendor/bundle --without development test"
  su - joruri -c "cp /var/share/jorurimail/config/original/*.yml /var/share/jorurimail/config/"
}

others() {
  echo 'This OS is not supported.'
  exit
}

if [ -f /etc/centos-release ]; then
  centos
elif [ -f /etc/lsb-release ]; then
  if grep -qs Ubuntu /etc/lsb-release; then
    ubuntu
  else
    others
  fi
else
  others
fi

touch $DONE_FLAG
