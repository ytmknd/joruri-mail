#!/bin/bash
DONE_FLAG="/tmp/$0_done"

RUBY_VERSION='ruby-1.9.2-p290'
RUBY_SOURCE_URL="http://cache.ruby-lang.org/pub/ruby/1.9/$RUBY_VERSION.tar.bz2"

echo "#### Install $RUBY_VERSION ####"
if [ -f $DONE_FLAG ]; then exit; fi
echo '-- PRESS ENTER KEY --'
read KEY

ubuntu() {
  echo 'Ubuntu will be supported shortly.'
}

centos() {
  echo "It's CentOS!"

  yum install -y wget gcc-c++ patch libyaml-* libjpeg-devel libpng-devel librsvg2-devel ghostscript-devel curl-devel libevent libevent-devel openssl openssl-devel 

  cd /usr/local/src
  rm -rf $RUBY_VERSION.tar.bz2 $RUBY_VERSION
  wget $RUBY_SOURCE_URL
  tar jxf $RUBY_VERSION.tar.bz2

  # patch
  yum install -y patch
  cd /usr/local/src/ruby-1.9.2-p290/ext/openssl/
  wget http://joruri.org/download/jorurimail/ruby1.9.2-p290-ossl_pkey_ec.patch
  patch < ruby1.9.2-p290-ossl_pkey_ec.patch

  # ruby make install
  cd /usr/local/src
  cd $RUBY_VERSION && ./configure && make && make install

  # rubygems
  gem install rubygems-update -v 1.6.2
  update_rubygems

  gem install rails -v 3.0.0
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
