# Podman セットアップガイド

このプロジェクトは Docker Compose と Podman Compose の両方で動作します。
`bin/podman-phase*` スクリプトが Podman 用の対応スクリプトです。

## 必要なバージョン

| ツール | 最低バージョン | 理由 |
|---|---|---|
| podman | 4.4 | `podman compose` サブコマンド内蔵 |
| podman-compose | 1.0.6 | `depends_on: condition: service_healthy` 対応 |

バージョン確認:

```sh
podman --version
podman compose version
```

---

## macOS セットアップ

### 1. Podman インストール

```sh
brew install podman
```

### 2. Podman Machine 初期化・起動

```sh
podman machine init
podman machine start
```

ARM Mac (M1/M2/M3) で `platform: linux/amd64` のイメージを実行するために
QEMU エミュレーションが使われます。初回ビルドは時間がかかります。

### 3. 動作確認

```sh
podman info
podman compose version
```

---

## Linux セットアップ

### Fedora / RHEL / CentOS Stream

```sh
sudo dnf install -y podman podman-compose
```

### Ubuntu / Debian

```sh
sudo apt-get install -y podman
pip3 install podman-compose
```

### rootless Podman の確認

```sh
podman info | grep -A5 'rootlessInfo'
```

rootless モードでは:
- コンテナ内の UID 0 (root) はホストのあなたのユーザー UID にマップされます
- コンテナ内の UID 1000 (joruri) はホストのサブ UID にマップされます
- entrypoint の `gosu joruri` はコンテナ内でのユーザー切り替えなので正常動作します
- `CHOWN_SOURCE_TREE=1` によるバインドマウント上の `chown` もユーザー名前空間内で完結するため正常動作します

### SELinux 有効環境 (Fedora / RHEL / CentOS)

SELinux が有効なホストではバインドマウントにラベルが必要です。
`docker-compose.selinux.yml` override ファイルを使用してください:

```sh
# 各コマンドに -f オプションを追加する場合
podman compose -f docker-compose.yml -f docker-compose.selinux.yml build app

# 環境変数で常に適用する場合 (推奨)
export COMPOSE_FILE=docker-compose.yml:docker-compose.selinux.yml
bin/podman-phase1 build
```

`COMPOSE_FILE` 環境変数は `.env` ファイルに書いておくと便利です:

```sh
echo 'COMPOSE_FILE=docker-compose.yml:docker-compose.selinux.yml' >> .env
```

---

## 各フェーズの実行

Docker のスクリプトと 1:1 対応しています。`docker` を `podman` に読み替えるだけです。

### Phase 1 (Ubuntu 18.04 / Ruby 2.3 / Rails 5.0)

```sh
bin/podman-phase1 build    # イメージビルド
bin/podman-phase1 check    # Ruby バージョン確認 + Rails 起動確認
bin/podman-phase1 up       # Rails サーバー起動 http://localhost:3000/
bin/podman-phase1 all      # build → check → up を一括実行
```

### Phase 2 (Rails 5 安定化 / Ruby アップグレード)

```sh
bin/podman-phase2 build                 # Ruby 2.3 で Rails 5 イメージビルド
bin/podman-phase2 check                 # 起動確認 http://localhost:3001/
bin/podman-phase2 ruby25-build          # Ruby 2.5 イメージビルド
bin/podman-phase2 ruby25-check          # Ruby 2.5 起動確認 http://localhost:3002/
bin/podman-phase2 ruby27-build          # Ruby 2.7 イメージビルド
bin/podman-phase2 ruby27-check          # Ruby 2.7 起動確認 http://localhost:3003/
bin/podman-phase2 bundle-update-rails50 # Gemfile.lock を Rails 5.0.x 最新パッチに更新
bin/podman-phase2 bundle-update-rails51 # Rails 5.1 へ更新 (Ruby 2.5 サービス対象)
bin/podman-phase2 bundle-update-rails52 # Rails 5.2 へ更新 (Ruby 2.5 サービス対象)
```

### Phase 3 (Ubuntu 20.04 / Ruby 2.7 および Ubuntu 22.04 / Ruby 3.1)

```sh
bin/podman-phase3 ubuntu20-build        # Ubuntu 20 イメージビルド
bin/podman-phase3 ubuntu20-check        # 起動確認
bin/podman-phase3 ubuntu20-stack-up     # web + proxy + worker + scheduler 起動
bin/podman-phase3 ubuntu20-stack-check  # プロキシ疎通確認 http://localhost:3005/
bin/podman-phase3 ubuntu20-smoke        # 非破壊スモークテスト (SMTP/IMAP/delayed_job)

bin/podman-phase3 ubuntu22-build        # Ubuntu 22 イメージビルド
bin/podman-phase3 ubuntu22-check        # 起動確認 http://localhost:3006/
bin/podman-phase3 ubuntu22-stack-up     # web + proxy + worker + scheduler 起動
bin/podman-phase3 ubuntu22-stack-check  # プロキシ疎通確認 http://localhost:3007/
```

### Phase 5 (Ubuntu 26.04 / Ruby 4.0)

```sh
bin/podman-phase5 ubuntu26-build        # Ubuntu 26 イメージビルド
bin/podman-phase5 ubuntu26-check        # Ruby + Rails + YJIT 起動確認
bin/podman-phase5 ubuntu26-yjit-check   # YJIT 有効確認のみ
bin/podman-phase5 ubuntu26-test         # Rails テストスイート実行
bin/podman-phase5 ubuntu26-assets       # アセットプリコンパイル
bin/podman-phase5 ubuntu26-up           # Rails サーバー起動 http://localhost:3008/
bin/podman-phase5 ubuntu26-stack        # proxy + worker + scheduler 起動
bin/podman-phase5 ubuntu26-security     # Brakeman + bundler-audit セキュリティ検査
bin/podman-phase5 ubuntu26-system-test  # Selenium システムテスト実行
```

---

## トラブルシューティング

### `podman compose` が見つからない

```
ERROR: 'podman compose' not available.
```

podman-compose をインストールしてください:

```sh
# macOS
brew install podman-compose

# Linux
pip3 install --user podman-compose
```

### `condition: service_healthy` が無視される

podman-compose < 1.0.6 では `depends_on: condition: service_healthy` が無視されます。
この場合、DB や IMAP が起動する前にアプリが起動し接続エラーになることがあります。

対処: podman-compose をアップグレードするか、DB/IMAP が起動完了してからアプリを起動してください:

```sh
podman compose up -d db imap
# DB の healthcheck が green になるまで待つ
podman compose up app
```

### ARM Mac で linux/amd64 イメージのビルドが遅い

M1/M2/M3 Mac では `platform: linux/amd64` の指定により QEMU エミュレーションが使われます。
これは Docker Desktop でも同様です。対処方法はありません (想定内の動作です)。

### バインドマウントで Permission denied (Linux rootless)

SELinux が有効な場合は「SELinux 有効環境」の節を参照してください。

SELinux が無効でも Permission denied が出る場合、サブ UID の設定が不足している可能性があります:

```sh
# /etc/subuid と /etc/subgid にエントリがあるか確認
grep "$(whoami)" /etc/subuid /etc/subgid

# エントリがなければ追加
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$(whoami)"
podman system migrate
```

### ボリュームの所有権エラー (rootless Linux)

named volume 内のファイルが joruri (UID 1000) ではなく別の UID で見える場合:

```sh
# コンテナ内から確認
podman compose run --rm app id
podman compose run --rm app ls -la vendor/bundle

# ボリュームを初期化して再作成
podman compose down -v
bin/podman-phase1 build
```

### `gosu: command not found`

gosu はアプリ Dockerfile でインストールされます。イメージを再ビルドしてください:

```sh
bin/podman-phase1 build
```

### ポート競合

同じポートで Docker と Podman を同時起動しようとすると競合します。
Docker Compose でサービスを停止してから Podman Compose を起動してください:

```sh
docker compose down
bin/podman-phase1 up
```
