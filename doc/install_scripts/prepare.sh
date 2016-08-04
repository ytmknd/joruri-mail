#!/bin/bash

INSTALL_SCRIPTS_URL='https://raw.githubusercontent.com/joruri/joruri-mail/master/doc/install_scripts'
# INSTALL_SCRIPTS_URL='https://raw.githubusercontent.com/joruri/joruri-mail/develop/doc/install_scripts'

echo '#### Prepare to install ####'

ubuntu() {
  echo 'Ubuntu will be supported shortly.'
}

centos() {
  echo "It's CentOS6!"

  yum install -y epel-release
  yum install -y wget git patch

  cd /usr/local/src

  files=('install_ruby.sh' 'install_joruri.sh' 'install_apache.rb' 'install_mysql.rb'
         'configure_joruri.rb' 'start_servers.sh')

  rm -f install_scripts.txt
  for file in ${files[@]}; do
    echo "$INSTALL_SCRIPTS_URL/$file" >> install_scripts.txt
  done

  wget -i install_scripts.txt

  for file in ${files[@]}; do
    chmod 755 $file
  done

  rm -f install_all.sh
  for file in ${files[@]}; do
    echo "./$file" >> install_all.sh
    if [ $file = 'install_ruby.sh' ]; then
      echo ". /etc/profile" >> install_all.sh
    fi
  done
cat <<'EOF' >> install_all.sh


echo "
-- インストールを完了しました。 --

  画面: `ruby -ryaml -e "puts YAML.load_file('/var/share/jorurimail/config/core.yml')['production']['uri']"`_admin

    管理者（システム管理者）
    ユーザーID   : admin
    パスワード : admin

１．MySQL の root ユーザーはパスワードが pass に設定されています。適宜変更してください。
    # mysqladmin -u root -prootpass password 'pass'
２．MySQL の joruri ユーザーはパスワードが pass に設定されています。適宜変更してください。
    mysql> SET PASSWORD FOR joruri@localhost = PASSWORD('pass');
    また、変更時には /var/share/jorurimail/config/database.yml も合わせて変更してください。
    # vi /var/share/jorurimail/config/database.yml
３．メールサーバーの接続情報を設定してください。
    # vi /var/share/jorurimail/config/smtp.yml
    # vi /var/share/jorurimail/config/imap.yml
４．メールアカウントのドメインを設定してください。
    # vi /var/share/jorurimail/config/core.yml


"
EOF
  chmod 755 install_all.sh

echo '
-- インストールを続けるには以下のコマンドを実行してください。 --

# cd /usr/local/src && /usr/local/src/install_all.sh
'
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
