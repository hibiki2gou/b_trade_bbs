# B-Trade BBS — 設計書

このファイルは「今どう作られているか」を記す。判断の理由や経緯は
[roadmap.md](roadmap.md) の「決定事項」を参照。

---

## 1. データ構造

```
Board（カテゴリ）
 └─< Topic（弾）
      ├─< Card（カード＝選手×弾）>── Player（選手）
      └─< Post（募集）>──────────── wanted_card は Card を指す
```

- **Board（カテゴリ）** … 掲示板の大きな区分け。例: トレード募集
- **Topic（弾）** … カードセット。スレッドにあたる。例: 記録達成カード
- **Player（選手）** … 選手。所属クラブを1回だけ持つ
- **Card（カード）** … 選手 × 弾 の交差点。レア度・カード名を持つ
- **Post（募集）** … トレードの書き込み。欲しいカードを1枚指す

### なぜこの形か（要点）

- **選手を独立させた**: 1人の選手のカードは複数の弾に散らばる。所属クラブを
  カードごとに書くと重複してズレるので、選手に1回だけ持たせる。
- **レア度はカードの属性**: 同じ選手でも弾ごとにレア度が違うため、Card に持たせる。
- **同一選手・同一弾の複数カード**（得点記録／アシスト記録）は Card.name で区別する。

---

## 2. テーブル定義（実装済み）

### boards
| カラム | 型 | 制約 | 説明 |
|---|---|---|---|
| name | string | NOT NULL | カテゴリ名 |
| slug | string | NOT NULL, UNIQUE | URL用の名札（英小文字・数字・ハイフン） |
| description | text | | 説明 |
| position | integer | NOT NULL, default 0 | 並び順 |

### topics（弾）
| カラム | 型 | 制約 | 説明 |
|---|---|---|---|
| board_id | references | NOT NULL, FK→boards | 所属カテゴリ |
| name | string | NOT NULL | 弾の名前 |
| slug | string | NOT NULL | 名札。画像ファイル名にも使う。(board_id, slug) でUNIQUE |
| description | text | | 説明 |
| position | integer | NOT NULL, default 0 | 並び順 |

### players（選手）
| カラム | 型 | 制約 | 説明 |
|---|---|---|---|
| name | string | NOT NULL, UNIQUE | 選手名（この表記が正） |
| team | string | NOT NULL | 所属クラブ |

### cards（カード）
| カラム | 型 | 制約 | 説明 |
|---|---|---|---|
| topic_id | references | NOT NULL, FK→topics | どの弾か |
| player_id | references | NOT NULL, FK→players | どの選手か |
| name | string | NOT NULL, default "" | カード名（得点記録 等）。1弾1種類なら "" |
| rarity | integer | NOT NULL | レア度 1〜5 |

- UNIQUE(topic_id, player_id, name) … 同じ選手・弾・カード名の二重登録を防ぐ
- name を NULL でなく "" にしているのは、SQLite で NULL 同士が「別物」扱いになり
  重複を防げないため。

### posts（募集）
| カラム | 型 | 制約 | 説明 |
|---|---|---|---|
| topic_id | references | NOT NULL, FK→topics | どの弾スレッドか |
| wanted_card_id | references | NOT NULL, FK→cards | 欲しいカード（選択式） |
| offered_cards | text | | 出せるカード（手入力） |
| note | text | | 備考 |
| nickname | string | NOT NULL | 投稿者名（ログイン導入までは手入力） |
| status | integer | NOT NULL, default 0 | 0=募集中 / 1=成立済み |
| completed_at | datetime | | 成立日時 |

---

## 3. モデルの責務

- **Board**: `has_many :topics`。slug の形式・一意性を検証。`scope :ordered`
- **Topic**: `belongs_to :board` / `has_many :cards, :posts`。`image_path`（sets/<slug>.jpg）
- **Player**: `has_many :cards` / `has_many :topics, through: :cards`。name 一意
- **Card**: `belongs_to :topic, :player`。rarity 1..5 を検証。
  `label`（河村勇輝（得点記録））、`stars`（★★★★☆）、`delegate :team, to: :player`
- **Post**: `belongs_to :topic` / `belongs_to :wanted_card, class_name: "Card"`。
  `enum :status`、`scope :open_posts / :completed_posts / :recent`、`complete!`

---

## 4. 画面の流れ

```
トップ（カテゴリ一覧）
   ↓ カテゴリを選ぶ
弾一覧（Topic 一覧）        ← 各弾の画像・名前
   ↓ 弾を選ぶ
弾スレッド詳細              ← 募集一覧 ＋ 投稿フォーム
```

### 投稿フォームの項目

- 欲しいカード … その弾の Card から**選択**（選手名・カード名・★で表示）
- 出せるカード … **手入力**（全弾から来るので選択式にしない）
- 備考 … 自由入力（よろしくお願いします、希望する交換方法 など）
- ニックネーム … 手入力（ログイン導入後は不要になる）
- ボタン … 投稿 / キャンセル

### 表示ルール

| 状態 | 一覧表示 | アカウントID |
|---|---|---|
| 募集中 | 表示 | ログイン済みユーザーにだけ表示（ログイン導入後） |
| 成立済み | 既定は非表示。トグルで閲覧可 | **誰にも表示しない** |

成立済みの一覧は「何と何が交換されたか」の記録＝**レート表**として価値を持つ。

---

## 5. 技術構成

| | |
|---|---|
| Rails | 8.1.3 |
| Ruby | 3.4.10 |
| DB | SQLite 3（開発）。公開時に永続化 or PostgreSQL 移行を判断 |
| 実行環境 | Docker / Docker Compose |
| ポート | ホスト 3001 → コンテナ 3000（3000は別プロジェクトが使用中のため） |

- 開発は `Dockerfile.dev` + `compose.yaml`。本番用 `Dockerfile` は Rails 生成のまま未使用
- `.claude/` は git・docker の両方で除外済み（作業用ディレクトリのため）

---

## 6. マスタデータの管理

- 弾・選手・カードは `db/seeds/card_sets.yml` に記述（唯一の情報源）
- `docker compose exec web bin/rails db:seed` で投入。冪等（何度実行しても同じ）
- seed は投入前に検証し、書き間違い（slug の誤り・レア度範囲外・カード名の
  未記入/重複）を見つけたら中断して理由を表示する
- 新しい弾・カードの追加は「クリスマス弾に河村のSRを追加して」のように依頼すれば
  YAML に反映する運用を想定
