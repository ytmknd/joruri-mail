# Podman セットアップガイド

このプロジェクトは Docker と Podman の両方で動作します。
`bin/phase5` スクリプトがランタイムを自動検出し、各環境の差異を吸収します。

## 動作確認済み環境

| 環境 | ホスト CPU | SELinux | 用途 |
|---|---|---|---|
| macOS (Apple Silicon M1/M2/M3) | ARM64 | なし | 開発機 |
| AlmaLinux 9 (x86_64) | x86_64 | Enforcing | 本番 / CI |

---

## macOS セットアップ（開発機）

### 1. Podman Desktop インストール（推奨）

[Podman Desktop](https://podman-desktop.io/) をインストールすると Podman Machine が
自動セットアップされます。

または Homebrew から:

```sh
brew install podman podman-compose
podman machine init
podman machine start
```

### 2. 動作確認

```sh
podman --version          # 4.4 以上
podman compose version    # podman-compose が見つかること
podman machine list       # Currently running であること
```

### 3. ビルドと起動

```sh
bin/phase5 ubuntu26-build   # linux/amd64 イメージをビルド（QEMU エミュレーション）
bin/phase5 ubuntu26-check   # Ruby 4 + Rails 8 + YJIT の起動確認
bin/phase5 ubuntu26-up      # http://localhost:3008/
```

`bin/phase5` は Podman を自動検出します。`PHASE5_RUNTIME=podman` で明示指定も可能。

> **ビルド時間について**
> Apple Silicon では `platform: linux/amd64` により QEMU x86_64 エミュレーションで
> ビルドが走ります。Ruby 4.0 のコンパイルを含む初回ビルドは **60〜90 分**かかります。
> 2 回目以降はキャッシュが利用されます。

---

## AlmaLinux 9 セットアップ（本番 / CI）

AlmaLinux 9 は x86_64 ネイティブのため、`platform: linux/amd64` のコンテナは
**QEMU なしで直接実行**されます。SELinux は Enforcing がデフォルトですが、
`bin/phase5` が自動検出して `docker-compose.selinux.yml` を適用します。

### 1. Podman と podman-compose のインストール

```sh
sudo dnf install -y epel-release
sudo dnf install -y podman python3-podman-compose
```

バージョン確認:

```sh
podman --version          # 4.x 以上
podman-compose --version
```

### 2. rootless Podman の確認

```sh
# subuid / subgid が設定されているか確認
grep "$(whoami)" /etc/subuid /etc/subgid

# エントリがなければ追加
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$(whoami)"
podman system migrate
```

### 3. ビルドと起動

```sh
bin/phase5 ubuntu26-build   # linux/amd64 イメージをビルド（ネイティブ実行）
bin/phase5 ubuntu26-check   # Ruby 4 + Rails 8 + YJIT の起動確認
bin/phase5 ubuntu26-up      # http://localhost:3008/
```

SELinux は `bin/phase5` が自動対応します（手動設定不要）。
`getenforce` が `Enforcing` を返す場合、`docker-compose.selinux.yml` が
自動的に `COMPOSE_FILE` に追加されます。

---

## 共通: 主なコマンド

```sh
bin/phase5 ubuntu26-build        # イメージビルド
bin/phase5 ubuntu26-check        # Ruby + Rails + YJIT 起動確認
bin/phase5 ubuntu26-yjit-check   # YJIT 有効確認のみ（DB 不要）
bin/phase5 ubuntu26-test         # Rails テストスイート実行
bin/phase5 ubuntu26-assets       # アセットプリコンパイル
bin/phase5 ubuntu26-up           # Rails サーバー起動
bin/phase5 ubuntu26-stack        # proxy + worker + scheduler 起動
bin/phase5 ubuntu26-security     # Brakeman + bundler-audit セキュリティ検査
bin/phase5 ubuntu26-system-test  # Selenium システムテスト実行
```

ランタイムの強制指定:

```sh
PHASE5_RUNTIME=podman bin/phase5 ubuntu26-check
PHASE5_RUNTIME=docker bin/phase5 ubuntu26-check
# または wrapper スクリプト経由:
bin/podman-phase5 ubuntu26-check
bin/docker-phase5 ubuntu26-check
```

---

## ビルドの技術的な注意点

### `--format docker` フラグ（Podman 専用）

Podman のデフォルトは OCI イメージフォーマットですが、OCI フォーマットは
Dockerfile の `SHELL` 命令を無視します。このプロジェクトの Dockerfile は
`SHELL ["/bin/bash", "-o", "pipefail", "-c"]` を使用しているため、
Podman でビルドする際は Docker フォーマットが必要です。

`bin/phase5` は Podman ランタイム選択時に `--format docker` を自動付与します。

### `runuser` による権限降格

コンテナのエントリポイントは root として起動し、`runuser` で `joruri`（UID 1000）に
権限を降格します。`runuser` は C 製バイナリ（util-linux）で QEMU エミュレーション下でも
安定動作します。`runuser` が利用できない環境では `gosu` にフォールバックします。

---

## トラブルシューティング

### `podman compose` が見つからない

```sh
# macOS
brew install podman-compose

# AlmaLinux 9
sudo dnf install -y epel-release
sudo dnf install -y python3-podman-compose

# その他 Linux
pip3 install --user podman-compose
```

### `condition: service_healthy` が動かない

podman-compose < 1.0.6 では `depends_on: condition: service_healthy` が無視されます。
DB/IMAP が起動してからアプリを起動してください:

```sh
podman compose up -d db imap
# healthcheck が green になるまで待つ（数十秒）
bin/phase5 ubuntu26-up
```

### バインドマウントで Permission denied（rootless Linux）

SELinux 以外の原因の場合、subuid が不足している可能性があります:

```sh
grep "$(whoami)" /etc/subuid /etc/subgid
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$(whoami)"
podman system migrate
```

### ボリュームを初期化してやり直す

```sh
podman compose down -v
bin/phase5 ubuntu26-build
```

### ポート競合

Docker と Podman を同時に使う場合はどちらか一方を停止してから起動してください:

```sh
docker compose down
bin/phase5 ubuntu26-up
```
