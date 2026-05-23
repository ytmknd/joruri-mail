FROM almalinux:9

ARG RUBY_VERSION=4.0.4
ARG BUNDLER_VERSION=2.5.23

ENV RBENV_ROOT=/usr/local/rbenv \
    PATH=/usr/local/rbenv/bin:/usr/local/rbenv/shims:/var/share/jorurimail/vendor/bundle/bin:$PATH \
    LANG=ja_JP.UTF-8 \
    LC_ALL=ja_JP.UTF-8 \
    RUBY_CONFIGURE_OPTS="--with-openssl-dir=/usr --enable-yjit" \
    BUNDLER_VERSION=${BUNDLER_VERSION}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN dnf install -y epel-release && \
    dnf module enable -y nodejs:20 && \
    dnf install -y \
      autoconf \
      bison \
      bzip2 \
      ca-certificates \
      cargo \
      curl \
      cyrus-sasl-devel \
      gdbm-devel \
      gcc \
      gcc-c++ \
      git \
      ImageMagick \
      ImageMagick-devel \
      libffi-devel \
      libicu-devel \
      libjpeg-turbo-devel \
      libpng-devel \
      librsvg2-devel \
      libxml2-devel \
      libxslt-devel \
      libyaml-devel \
      libzip-devel \
      make \
      mariadb \
      mariadb-devel \
      ncurses-devel \
      nodejs \
      openldap-devel \
      openssl-devel \
      patch \
      readline-devel \
      shared-mime-info \
      tzdata \
      glibc-langpack-ja \
      zlib-devel && \
    dnf clean all

RUN groupadd --gid 1000 joruri && \
    useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash joruri && \
    mkdir -p /var/share/jorurimail && \
    chown -R joruri:joruri /var/share/jorurimail

RUN git clone --depth 1 https://github.com/rbenv/rbenv.git "${RBENV_ROOT}" && \
    git clone --depth 1 https://github.com/rbenv/ruby-build.git "${RBENV_ROOT}/plugins/ruby-build" && \
    rbenv install "${RUBY_VERSION}" && \
    rbenv global "${RUBY_VERSION}" && \
    rbenv rehash && \
    gem install bundler -v "${BUNDLER_VERSION}" --no-document --force && \
    rbenv rehash

WORKDIR /var/share/jorurimail

COPY Gemfile Gemfile.phase5.lock ./
RUN cp Gemfile.phase5.lock Gemfile.lock && \
    bundle _${BUNDLER_VERSION}_ install --path vendor/bundle && \
    chown -R joruri:joruri /var/share/jorurimail

COPY docker/ubuntu18-ruby25/entrypoint.sh /usr/local/bin/joruri-entrypoint
RUN chmod +x /usr/local/bin/joruri-entrypoint

EXPOSE 3000

ENTRYPOINT ["joruri-entrypoint"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
