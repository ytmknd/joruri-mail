FROM ubuntu:26.04

ARG RUBY_VERSION=3.3.11
ARG BUNDLER_VERSION=2.5.23

ENV DEBIAN_FRONTEND=noninteractive \
    RBENV_ROOT=/usr/local/rbenv \
    PATH=/usr/local/rbenv/bin:/usr/local/rbenv/shims:/var/share/jorurimail/vendor/bundle/bin:$PATH \
    LANG=ja_JP.UTF-8 \
    LC_ALL=ja_JP.UTF-8 \
    RUBY_CONFIGURE_OPTS=--with-openssl-dir=/usr \
    BUNDLER_VERSION=${BUNDLER_VERSION}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      autoconf \
      bison \
      build-essential \
      bzip2 \
      ca-certificates \
      curl \
      default-mysql-client \
      git \
      gosu \
      imagemagick \
      libffi-dev \
      libgdbm-dev \
      libicu-dev \
      libjpeg-dev \
      libldap2-dev \
      libmagickcore-dev \
      libmagickwand-dev \
      libmariadb-dev \
      libncurses-dev \
      libpng-dev \
      libreadline-dev \
      librsvg2-dev \
      libsasl2-dev \
      libssl-dev \
      libxml2-dev \
      libxslt1-dev \
      libyaml-dev \
      libzip-dev \
      locales \
      nodejs \
      patch \
      shared-mime-info \
      tzdata \
      zlib1g-dev && \
    locale-gen ja_JP.UTF-8 && \
    rm -rf /var/lib/apt/lists/*

RUN existing_group="$(getent group 1000 | cut -d: -f1 || true)" && \
    if [[ -n "${existing_group}" && "${existing_group}" != "joruri" ]]; then \
      groupmod --new-name joruri "${existing_group}"; \
    elif [[ -z "${existing_group}" ]]; then \
      groupadd --gid 1000 joruri; \
    fi && \
    existing_user="$(getent passwd 1000 | cut -d: -f1 || true)" && \
    if [[ -n "${existing_user}" && "${existing_user}" != "joruri" ]]; then \
      usermod --login joruri --home /home/joruri --move-home --gid 1000 --shell /bin/bash "${existing_user}"; \
    elif [[ -z "${existing_user}" ]]; then \
      useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash joruri; \
    else \
      usermod --gid 1000 --shell /bin/bash joruri; \
    fi && \
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

COPY Gemfile Gemfile.lock ./
RUN bundle _${BUNDLER_VERSION}_ install --path vendor/bundle && \
    chown -R joruri:joruri /var/share/jorurimail

COPY docker/ubuntu18-ruby25/entrypoint.sh /usr/local/bin/joruri-entrypoint
RUN chmod +x /usr/local/bin/joruri-entrypoint

EXPOSE 3000

ENTRYPOINT ["joruri-entrypoint"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
