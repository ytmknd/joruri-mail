# Joruri Mail インストールマニュアル — AlmaLinux 9 / Podman

## 1. 想定環境

| 項目 | 内容 |
|---|---|
| OS | AlmaLinux 9 (x86_64) |
| コンテナランタイム | Podman 4.x 以上 |
| コンテナ構成 | podman-compose |
| アプリ | Rails 8.1 / Ruby 4.0 / Ubuntu 26.04 |
| DB | MySQL 5.7 (コンテナ) |
| メール | Postfix + Dovecot (コンテナ) |
| プロキシ | Nginx 1.26 (コンテナ) |
| SELinux | Enforcing（自動対応） |

AlmaLinux 9 は x86_64 ネイティブのため、`linux/amd64` コンテナは QEMU なしで直接実行されます。
SELinux は `bin/phase5` が自動検出して `docker-compose.selinux.yml` を適用します。

---

## 2. Podman と podman-compose のインストール

```sh
# EPEL リポジトリを有効化し Podman と podman-compose をインストール
sudo dnf install -y epel-release
sudo dnf install -y podman python3-podman-compose

# バージョン確認
podman --version          # 4.x 以上
podman-compose --version
```

---

## 3. rootless Podman の設定

rootless Podman（一般ユーザー権限）で動かすための設定を行います。

```sh
# subuid / subgid の確認
grep "$(whoami)" /etc/subuid /etc/subgid
```

エントリがない場合は追加:

```sh
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$(whoami)"
podman system migrate
```

ユーザーの systemd サービスを有効にする（自動起動で必要）:

```sh
sudo loginctl enable-linger "$(whoami)"
```

---

## 4. ソースコードの取得

```sh
cd ~
git clone https://github.com/joruri/joruri-mail.git
cd joruri-mail
```

---

## 5. 設定ファイルの準備

`docker/phase1/config/` の設定ファイルをカスタマイズします。

### 5.1 データベース設定 (`docker/phase1/config/database.yml`)

```yaml
production:
  adapter: mysql2
  database: jorurimail
  username: joruri
  password: <強力なパスワードに変更>
  timeout: 5000
  encoding: utf8
  host: db
```

### 5.2 アプリケーション設定 (`docker/phase1/config/core.yml`)

```yaml
production:
  title: Joruri Mail
  uri: https://<公開ドメイン>/     # 実際の URL に変更
  proxy:
  map_key:
  mail_domain: <メールドメイン>     # 例: example.com
```

### 5.3 SMTP 設定 (`docker/phase1/config/smtp.yml`)

外部 SMTP サーバーを使用する場合:

```yaml
production:
  address: <SMTPサーバーホスト>
  port: 587
  domain: <メールドメイ��>
  user_name: <SMTPユーザー>
  password: <SMTPパスワード>
  authentication: login
```

内蔵コンテナ (Postfix) をそのまま使う場合は変更不要です。

### 5.4 IMAP 設定 (`docker/phase1/config/imap.yml`)

外部 IMAP サーバーを使用する場合:

```yaml
production:
  address: <IMAPサーバーホスト>
  port: 143
  usessl: false
```

内蔵コンテナ (Dovecot) をそのまま使う場合は変更不要です。

### 5.5 秘密鍵の設定 (`docker/phase1/config/secrets.yml`)

```sh
# 秘密鍵を生成（Podman コンテナを使用）
podman run --rm docker.io/library/ruby:4.0 \
  ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"
```

生成された値を `secrets.yml` の production セクションに設定:

```yaml
production:
  secret_key_base: <生成した64バイトの16進数文字列>
```

### 5.6 MySQL パスワードの変更

`docker-compose.yml` の db セクションと `docker/phase1/config/database.yml` を一致させます。

`docker-compose.yml` の db セクションを編集:

```yaml
  db:
    environment:
      MYSQL_ROOT_PASSWORD: <rootパスワード>
      MYSQL_PASSWORD: <joruriパスワード>
```

---

## 6. RAILS_ENV の設定

`docker-compose.yml` の `app-ubuntu26-ruby4`・`app-ubuntu26-ruby4-worker`・
`app-ubuntu26-ruby4-scheduler` の environment を production に変更します:

```yaml
    environment:
      RAILS_ENV: production
      SECRET_KEY_BASE: <secrets.yml と同じ値>
```

---

## 7. イメージのビルド

```sh
bin/phase5 alma-build
```

> **Podman ビルドの技術的補足**
> `bin/phase5` は Podman 使用時に自動で `--format docker --platform linux/amd64` を付与します。
> AlmaLinux 9 は x86_64 ネイティブなので QEMU エミュレーションは不要です。
> AlmaLinux 9 ベースのイメージを使用するため Ubuntu 26.04 への依存はありません。

---

## 8. SELinux の確認

`bin/phase5` は起動時に `getenforce` を確認し、`Enforcing` の場合は自動で
`docker-compose.selinux.yml` を適用します。手動設定は不要です。

```sh
getenforce   # → Enforcing と表示されれば自動対応済み
```

---

## 9. データベースの初期化

```sh
# DB コンテナと imap コンテナを起動
podman compose up -d db imap

# DB が起動するまで待機（通常 30 秒程度）
podman compose ps   # db が healthy になるまで繰り返す

# スキーマ作成と初期データ投入
bin/phase5 alma-db-setup
```

---

## 10. アセットのプリコンパイル

```sh
bin/phase5 alma-assets
```

---

## 11. アプリの起動

### 動作確認（単体起動）

```sh
bin/phase5 alma-up
# → http://サーバーIP:3010/ でアクセス可能
```

### 本番環境（フルスタック起動）

```sh
podman compose --profile alma9 up -d app-almalinux9-ruby4
podman compose --profile alma9 up -d app-almalinux9-ruby4-proxy app-almalinux9-ruby4-worker app-almalinux9-ruby4-scheduler
# → http://サーバーIP:3011/ (Nginx 経由)
```

---

## 12. 動作確認

```sh
# Ruby + Rails + YJIT の確認
bin/phase5 alma-check

# テストスイートの実行
bin/phase5 alma-test

# セキュリティチェック
bin/phase5 alma-security
```

管理画面: `http://サーバーIP:3011/_admin/login`

---

## 13. systemd による自動起動（rootless Podman）

rootless Podman では Podman の systemd integration を使用します。

```sh
# ユーザー用の systemd サービスディレクトリを作成
mkdir -p ~/.config/systemd/user
```

`~/.config/systemd/user/joruri-mail.service` を作成:

```ini
[Unit]
Description=Joruri Mail (Podman Compose)
After=default.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=%h/joruri-mail
Environment=PHASE5_RUNTIME=podman
ExecStart=/usr/bin/bash -c 'bin/phase5 ubuntu26-up & \
  podman compose up -d app-ubuntu26-ruby4-proxy \
  app-ubuntu26-ruby4-worker app-ubuntu26-ruby4-scheduler'
ExecStop=/usr/bin/podman compose stop \
  app-ubuntu26-ruby4 app-ubuntu26-ruby4-proxy \
  app-ubuntu26-ruby4-worker app-ubuntu26-ruby4-scheduler
TimeoutStartSec=300

[Install]
WantedBy=default.target
```

```sh
systemctl --user daemon-reload
systemctl --user enable joruri-mail
systemctl --user start joruri-mail
```

サービスの状態確認:

```sh
systemctl --user status joruri-mail
```

---

## 14. サービス構成の概要

```
[ブラウザ]
    ↓ HTTP :80 (ホストの Nginx 等でリバースプロキシする場合)
[app-ubuntu26-ruby4-proxy] :3009
    ↓
[app-ubuntu26-ruby4] :3000 (Puma)
    ↓
[db] MySQL 5.7 :3306
[imap] Postfix :587 / Dovecot :143
[app-ubuntu26-ruby4-worker] delayed_job
[app-ubuntu26-ruby4-scheduler] webmail:cleanup (日次)
```

---

## 15. ログの確認

```sh
podman compose --profile alma9 logs -f app-almalinux9-ruby4          # アプリログ
podman compose --profile alma9 logs -f app-almalinux9-ruby4-worker   # ジョブワーカーログ
podman compose logs -f db                                             # MySQL ログ
podman compose logs -f imap                                           # メールサーバーログ
```

---

## 16. アップデート

```sh
cd ~/joruri-mail
git pull
bin/phase5 alma-build
podman compose --profile alma9 run --rm app-almalinux9-ruby4 bundle exec rails db:migrate
podman compose --profile alma9 restart app-almalinux9-ruby4 app-almalinux9-ruby4-worker app-almalinux9-ruby4-scheduler
```

---

## 17. トラブルシューティング

### コンテナが起動しない（SELinux 関連）

`bin/phase5` が SELinux を自動検出するため通常は不要ですが、手動確認する場合:

```sh
# SELinux の状態確認
getenforce

# 拒否ログの確認
sudo ausearch -m avc -ts recent | head -30
```

### subuid エラー

```sh
grep "$(whoami)" /etc/subuid /etc/subgid
# エントリがなければ追加
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$(whoami)"
podman system migrate
```

### ボリュームを初期化してやり直す

```sh
podman compose down -v
bin/phase5 ubuntu26-build
# 8. データベースの初期化 から再実行
```

### podman-compose が古い（`condition: service_healthy` が動かない）

```sh
sudo dnf update python3-podman-compose
# または
pip3 install --user --upgrade podman-compose
```
