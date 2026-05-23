# Joruri Mail インストールマニュアル — Ubuntu 26.04 / Docker

## 1. 想定環境

| 項目 | 内容 |
|---|---|
| OS | Ubuntu 26.04 LTS (x86_64) |
| コンテナランタイム | Docker Engine 25.x 以上 |
| コンテナ構成 | Docker Compose |
| アプリ | Rails 8.1 / Ruby 4.0 / Ubuntu 26.04 |
| DB | MySQL 5.7 (コンテナ) |
| メール | Postfix + Dovecot (コンテナ) |
| プロキシ | Nginx 1.26 (コンテナ) |

---

## 2. Docker のインストール

```sh
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

操作ユーザーを docker グループに追加（再ログイン後に有効）:

```sh
sudo usermod -aG docker $USER
```

インストール確認:

```sh
docker --version          # Docker version 25.x.x 以上
docker compose version    # Docker Compose version v2.x.x 以上
```

---

## 3. ソースコードの取得

```sh
cd /opt
sudo git clone https://github.com/joruri/joruri-mail.git
sudo chown -R $USER:$USER joruri-mail
cd joruri-mail
```

---

## 4. 設定ファイルの準備

`docker/phase1/config/` の設定ファイルをカスタマイズします。
テンプレートとして使用中の値を変更してください。

### 4.1 データベース設定 (`docker/phase1/config/database.yml`)

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

### 4.2 アプリケーション設定 (`docker/phase1/config/core.yml`)

```yaml
production:
  title: Joruri Mail
  uri: https://<公開ドメイン>/     # 実際の URL に変更
  proxy:
  map_key:
  mail_domain: <メールドメイン>     # 例: example.com
```

### 4.3 SMTP 設定 (`docker/phase1/config/smtp.yml`)

外部 SMTP サーバーを使用する場合:

```yaml
production:
  address: <SMTPサーバーホスト>
  port: 587
  domain: <メールドメイン>
  user_name: <SMTPユーザー>
  password: <SMTPパスワード>
  authentication: login
```

内蔵コンテナ (Postfix) をそのまま使う場合は変更不要です。

### 4.4 IMAP 設定 (`docker/phase1/config/imap.yml`)

外部 IMAP サーバーを使用する場合:

```yaml
production:
  address: <IMAPサーバーホスト>
  port: 143
  usessl: false
```

内蔵コンテナ (Dovecot) をそのまま使う場合は変更不要です。

### 4.5 秘密鍵の設定 (`docker/phase1/config/secrets.yml`)

```sh
# 秘密鍵を生成
docker run --rm ruby:4.0 ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"
```

生成された値を `secrets.yml` の production セクションに設定:

```yaml
production:
  secret_key_base: <生成した64バイトの16進数文字列>
```

### 4.6 MySQL パスワードの変更

`docker-compose.yml` の db サービスと `docker/phase1/config/database.yml` のパスワードを一致させてください。

`docker-compose.yml` の db セクション:

```yaml
  db:
    environment:
      MYSQL_ROOT_PASSWORD: <rootパスワード>
      MYSQL_PASSWORD: <joruriパスワード>
```

---

## 5. RAILS_ENV の設定

`docker-compose.yml` の `app-ubuntu26-ruby4` サービスの環境変数を production に変更します:

```yaml
  app-ubuntu26-ruby4:
    environment:
      RAILS_ENV: production
      SECRET_KEY_BASE: <secrets.yml と同じ値>
```

worker と scheduler サービスも同様に変更してください。

---

## 6. イメージのビルド

```sh
bin/phase5 ubuntu26-build
```

> **所要時間**: 初回は Ruby 4.0.4 のコンパイルを含むため 10〜30 分かかります。
> 2 回目以降はキャッシュが使用されます。

---

## 7. データベースの初期化

```sh
# DB コンテナと imap コンテナを起動
docker compose up -d db imap

# DB が起動するまで待機（healthcheck が healthy になるまで）
docker compose ps   # db が healthy になるまで繰り返す

# スキーマ作成と初期データ投入
bin/phase5 ubuntu26-db-setup
```

---

## 8. アセットのプリコンパイル

```sh
bin/phase5 ubuntu26-assets
```

---

## 9. アプリの起動

### 開発・テスト環境（単体起動）

```sh
bin/phase5 ubuntu26-up
# → http://サーバーIP:3008/ でアクセス可能
```

### 本番環境（フルスタック起動）

app (Puma) + proxy (Nginx) + worker (delayed_job) + scheduler を一括起動:

```sh
docker compose up -d app-ubuntu26-ruby4
docker compose up -d app-ubuntu26-ruby4-proxy app-ubuntu26-ruby4-worker app-ubuntu26-ruby4-scheduler
# → http://サーバーIP:3009/ (Nginx 経由)
```

---

## 10. 動作確認

```sh
# Ruby + Rails + YJIT の確認
bin/phase5 ubuntu26-check

# テストスイートの実行
bin/phase5 ubuntu26-test

# セキュリティチェック
bin/phase5 ubuntu26-security
```

管理画面: `http://サーバーIP:3009/_admin/login`

---

## 11. systemd による自動起動

`/etc/systemd/system/joruri-mail.service` を作成:

```ini
[Unit]
Description=Joruri Mail (Docker Compose)
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/joruri-mail
ExecStart=/usr/bin/docker compose up -d app-ubuntu26-ruby4 app-ubuntu26-ruby4-proxy app-ubuntu26-ruby4-worker app-ubuntu26-ruby4-scheduler
ExecStop=/usr/bin/docker compose stop app-ubuntu26-ruby4 app-ubuntu26-ruby4-proxy app-ubuntu26-ruby4-worker app-ubuntu26-ruby4-scheduler
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
```

```sh
sudo systemctl daemon-reload
sudo systemctl enable joruri-mail
sudo systemctl start joruri-mail
```

---

## 12. サービス構成の概要

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

## 13. ログの確認

```sh
docker compose logs -f app-ubuntu26-ruby4          # アプリログ
docker compose logs -f app-ubuntu26-ruby4-worker   # ジョブワーカーログ
docker compose logs -f db                          # MySQL ログ
docker compose logs -f imap                        # メールサーバーログ
```

---

## 14. アップデート

```sh
cd /opt/joruri-mail
git pull
bin/phase5 ubuntu26-build
docker compose run --rm app-ubuntu26-ruby4 bundle exec rails db:migrate
docker compose restart app-ubuntu26-ruby4 app-ubuntu26-ruby4-worker app-ubuntu26-ruby4-scheduler
```
