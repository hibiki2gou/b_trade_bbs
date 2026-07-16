# B-Trade BBS

Bリーグカードのトレード相手を見つけるための掲示板。
ダブったカードを無駄にせず、欲しい人へ橋渡しする「カードの物々交換所」を目指す。

## 技術構成

| | |
|---|---|
| Rails | 8.1.3 |
| Ruby | 3.4.10 |
| DB | SQLite 3 |
| 実行環境 | Docker / Docker Compose |

Ruby も Rails も Docker の中にだけ入っている。
ホスト側に Ruby や Rails を入れる必要はない。

## 使い方

初回だけイメージのビルドが要る。

```
docker compose up --build
```

2回目以降はこれだけ。

```
docker compose up
```

起動したらブラウザで **http://localhost:3001** を開く。

止めるとき。

```
docker compose down
```

### ポートが3000ではなく3001の理由

別プロジェクトが3000番を使っていてぶつかるため、ホスト側を3001にずらしている。
3000番が空いたら `compose.yaml` の `ports` を `"3000:3000"` に戻してよい。

## よく使うコマンド

コンテナの中で実行するので、頭に `docker compose exec web` を付ける。

```
docker compose exec web bin/rails console      # コンソール
docker compose exec web bin/rails db:migrate   # マイグレーション
docker compose exec web bin/rails test         # テスト
docker compose exec web bin/rails g model Foo  # ジェネレータ
docker compose exec web bash                   # シェルに入る
```

コードはホストからコンテナにマウントしているので、
**エディタで編集すればそのまま反映される**。build し直す必要はない。

build が要るのは `Dockerfile.dev` を変えたときだけ。
`Gemfile` に gem を足したときは、起動時に自動で `bundle install` が走る。

## ファイル構成のメモ

| ファイル | 役割 |
|---|---|
| `Dockerfile` | **本番用**。Rails が自動生成したもの。今は使っていない |
| `Dockerfile.dev` | **開発用**。`docker compose` が使うのはこっち |
| `compose.yaml` | 開発環境の構成 |
| `bin/docker-entrypoint-dev` | 起動のたびに走る後始末（pid削除・bundle・db:prepare） |

## データの構造（予定）

```
Board（カテゴリ） 1 ──< Topic（スレッド） 1 ──< Post（レス）
```

- **Board** … 掲示板の大きな区分け（例: 欲しいカードを探す / 譲れるカードを出す）
- **Topic** … ひとつの話題（例: 「河村のMVPカード探してます」）
- **Post** … スレッドへの書き込み。スレッドを立てたときの最初の一文もこれ

## 画面の流れ（予定）

```
トップ（カテゴリ一覧）
   ↓ カテゴリを選ぶ
カテゴリの中（スレッド一覧）
   ↓ スレッドを選ぶ / 新しく立てる
スレッド詳細（レス一覧 ＋ 返信フォーム）
```

## デザインの方向性

Bリーグっぽく、黒 × 赤。ダークな背景に赤のアクセントで、スポーティに。

## ドキュメント

設計・企画・ロードマップは `docs/` にまとめている。

- [docs/overview.md](docs/overview.md) … 企画とこれまでの流れ
- [docs/design.md](docs/design.md) … 設計書（データ構造・画面・技術）
- [docs/roadmap.md](docs/roadmap.md) … 進め方・決定事項・宿題（未決事項）
