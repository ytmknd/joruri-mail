#!/bin/bash
DONE_FLAG="/tmp/$0_done"

RUBY_VERSION='ruby-2.3.1'
RUBY_SOURCE_URL="http://cache.ruby-lang.org/pub/ruby/2.3/$RUBY_VERSION.tar.bz2"

echo "#### Install $RUBY_VERSION ####"
if [ -f $DONE_FLAG ]; then exit; fi
echo '-- PRESS ENTER KEY --'
read KEY

ubuntu() {
  echo 'Ubuntu will be supported shortly.'
}

centos() {
  echo "It's CentOS!"

  yum install -y make gcc-c++ bzip2 openssl-devel libyaml-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel

  cd /usr/local/src
  rm -rf $RUBY_VERSION.tar.bz2 $RUBY_VERSION
  wget $RUBY_SOURCE_URL
  tar jxf $RUBY_VERSION.tar.bz2

  # ruby make install
  cd /usr/local/src
  cd $RUBY_VERSION && ./configure && make && make install

  # bundler
  gem install bundler -v 1.11.2
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
