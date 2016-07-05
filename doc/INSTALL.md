# Joruri Mail v2.0.0 インストールマニュアル / 2016.07.05

## 想定環境

[システム]
|Software|Version|
|:---|:---|
|OS|CentOS 6.7 (64bit)|
|Webサーバ|Apache 2.2|
|DBシステム|MySQL 5|
|Ruby|2.3.1|
|Rails|4.2.6|
|Mailサーバ|SMTP, IMAP4|

[ネットワーク関連設定]
|項目|設定|
|:---|:---|
|IPアドレス|192.168.0.2|
|メールドメイン|localhost.localdomain.jp|

## CentOS のインストール

CentOSをインストールします。

※インストール完了後、ご利用になられる環境に合わせて適切なセキュリティ設定をお願いします。
CentOSに関するセキュリティ設定については、本マニュアルの範囲外となります。

rootユーザに変更します。

    $ su -

## 事前準備

必要なパッケージをインストールします。

    # yum -y install epel-release
    # yum -y install wget git

## Ruby のインストール

依存パッケージをインストールします。

    # yum -y install make gcc-c++ patch bzip2 openssl-devel libyaml-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel

Rubyをインストールします。

    # cd /usr/local/src
    # wget https://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.1.tar.gz
    # tar xvzf ruby-2.3.1.tar.gz
    # cd ruby-2.3.1
    # ./configure
    # make && make install

bundler をインストールします。

    # gem install bundler -v 1.11.2

## Apache のインストール

Apacheをインストールします。

    # yum -y install httpd-devel
  
 設定ファイルを編集します。

    # vi /etc/httpd/conf/httpd.conf
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    ServerName 192.168.0.2    #変更
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

自動起動に設定します。

    # /sbin/chkconfig httpd on

## Passenger のインストール

Passengerをインストールします。

    # yum -y install curl-devel
    # gem install passenger -v 5.0.23
    # passenger-install-apache2-module -a
    (画面の内容を確認して Enterキーを押してください)

## MySQL のインストール

MySQLをインストールします。

    # yum -y install mysql-server

文字エンコーディングの標準を UTF-8 に設定します。

    # vi /etc/my.cnf
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    [mysqld]
    default-character-set=utf8    #追加
    
    [client]                      #追加（末尾に追加）
    default-character-set=utf8    #追加
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

MySQLを起動します。

    # /usr/bin/mysql_install_db --user=mysql
    # /sbin/service mysqld start

自動起動に設定します。

    # /sbin/chkconfig mysqld on
  
rootユーザのパスワードを設定します。

    # /usr/bin/mysqladmin -u root password "pass"

## Joruri Mail のインストール

依存パッケージをインストールします。

    # yum -y install ImageMagick-devel libjpeg-devel libpng-devel librsvg2-devel　libxml2-devel libxslt-devel mysql-devel openldap-devel shared-mime-info libicu-devel npm
    # npm install bower -g

Joruriユーザを作成します。

    # useradd -m joruri

DBユーザを作成します。

    # /usr/bin/mysql -u root -ppass -e "grant all on *.* to joruri@localhost IDENTIFIED BY 'pass'"

ソースコードをダウンロードします。

    # mkdir /var/share
    # git clone https://github.com/joruri/joruri-mail.git /var/share/jorurimail
    # chown -R joruri:joruri /var/share/jorurimail

Joruriユーザに変更します。

    # su - joruri
    $ cd /var/share/jorurimail

必要ライブラリをインストールします。

    $ bundle install --path vendor/bundle --without development test
    $ bundle exec bower:install RAILS_ENV=production

## Joruri Mail の設定

### 設定ファイルの編集

サンプル設定ファイルをコピーします。

    $ cp /var/share/jorurimail/config/original/* /var/share/jorurimail/config/

基本設定を編集します。

    $ vi config/core.yml
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    title  : Joruri Mail
    uri    : http://192.168.0.2/
    proxy  : ※プロキシ
    mail_domain: ※メールドメイン
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

    ※プロキシ
    プロキシサーバが導入されている場合は  http://example:8080/ の様に記述してください。

DB, SMTP, IMAPサーバ接続情報を設定します。

    $ vi config/database.yml
    $ vi config/smtp.yml
    $ vi config/imap.yml

Joruri Gwへのシングルサインオン接続情報を設定します。（Joruri Gwと連携する場合）

    $ vi config/sso.yml

VirtualHostを設定します。

    $ vi config/virtual-hosts/jorurimail.conf

シークレットキーを設定します。

    $ bundle exec rake secret RAILS_ENV=production
      (出力されたシークレットキーをコピーします)
    $ vi config/secrets.yml
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    production:
      secret_key_base: (コピーしたシークレットキーを貼り付けます)
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

### データベースの作成

データベースを作成します。

    $ /usr/bin/mysql -u root -ppass -e "create database jorurimail"

テーブルを作成します。

    $ bundle exec rake db:schema:load RAILS_ENV=production

初期データを登録します。

    $ bundle exec rake db:seed RAILS_ENV=production

サンプルデータを登録します。

    $ bundle exec rake db:seed:demo RAILS_ENV=production

### assets のコンパイル

assetsをコンパイルします。

    $ bundle exec rake assets:precompile RAILS_ENV=production

### cron タスクの登録

cron タスクを登録します。

    $ bundle exec whenever -i -s 'environment=production'

## サーバー起動

Apacheに設定を追加します。

    $ su -
    # cp /var/share/jorurimail/config/samples/passenger.conf /etc/httpd/conf.d/
    # ln -s /var/share/jorurimail/config/virtual-host/jorurimail.conf /etc/httpd/conf.d/jorurimail.conf

Apache を起動します。

    # /sbin/service httpd configtest
    # /sbin/service httpd start

## 画面確認

ここまでの手順で Joruri Mail の画面にアクセスできます。

  http://192.168.0.2/

次のユーザが登録されています。

    管理者（システム管理者）
      ユーザID   : admin
      パスワード : admin

    一般ユーザ（徳島　太郎）
      ユーザID   : user1
      パスワード : user1

    一般ユーザ（阿波　花子）
      ユーザID   : user2
      パスワード : user2

    一般ユーザ（吉野　三郎）
      ユーザID   : user3
      パスワード : user3
