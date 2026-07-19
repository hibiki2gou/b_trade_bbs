# TRADE COURT — 設計書

このファイルは「今どう作られているか」を記す。判断の理由や経緯は
[roadmap.md](roadmap.md) の「決定事項」を参照。

---

## 1. データ構造

```
Team（チーム）──< Player（選手）──< Card（カード）>── Topic（弾）>── Board（裏方）
                                        ↑       ↑
                          Post（募集）──┴───────┘
                            ├─ Wish  → wanted_cards （欲しいカード・複数）
                            └─ Offer → offered_cards（出せるカード・複数）
```

- **Board** … 弾をまとめる裏方の区分け。画面には出さない
- **Topic（弾）** … カードセット。掲示板の単位。例: OCEAN
- **Team（チーム）** … クラブ。こちらも掲示板の入口になる
- **Player（選手）** … 背番号・ポジション・所属チームを持つ
- **Card（カード）** … 選手 × 弾 の交差点。レア度（1〜5）とカード名を持つ
- **Post（募集）** … 欲しい／出せるカードを、それぞれ複数指定できる書き込み
- **Wish / Offer** … 募集とカードをつなぐ中間テーブル

### なぜこの形か（要点）

- **選手を独立させた**: 1人の選手のカードは複数の弾に散らばる。所属クラブを
  カードごとに書くと重複してズレるので、選手に1回だけ持たせる
- **チームもモデルにした**: 弾と対等に「名前・slug・画像・並び順」を持たせ、
  チームからも掲示板に入れるようにするため
- **レア度はカードの属性**: 同じ選手でも弾ごとにレア度が違うため Card に持たせる
- **同一選手・同一弾の複数カード**（得点記録／アシスト記録）は `Card.name` で区別する
- **欲しい／出せるを対称にした**: どちらも複数枚を選べる中間テーブル方式。
  これにより「このカードを出せる人」も検索できる
- **募集は弾に所属しない**: 欲しいカードが複数弾にまたがりうるため `posts.topic_id` を廃止。
  どの掲示板に出るかは**欲しいカードから導く**

---

## 2. テーブル定義（実装済み）

### boards（裏方の区分け）
| カラム | 型 | 制約 |
|---|---|---|
| name / slug | string | NOT NULL、slug は UNIQUE |
| description | text | |
| position | integer | NOT NULL, default 0 |

### topics（弾）
| カラム | 型 | 制約 |
|---|---|---|
| board_id | references | NOT NULL, FK→boards |
| name / slug | string | NOT NULL、(board_id, slug) で UNIQUE |
| description | text | |
| position | integer | NOT NULL, default 0（**小さいほど新しい**） |

### teams（クラブ）
| カラム | 型 | 制約 |
|---|---|---|
| name | string | NOT NULL |
| slug | string | NOT NULL, UNIQUE |
| position | integer | NOT NULL, default 0（指定の並び順） |

### players（選手）
| カラム | 型 | 制約 |
|---|---|---|
| name | string | NOT NULL, UNIQUE |
| team_id | references | NOT NULL, FK→teams |
| jersey_number | integer | 0〜99、(team_id, jersey_number) で UNIQUE |
| position | string | 例: SG/SF |

### cards（カード）
| カラム | 型 | 制約 |
|---|---|---|
| topic_id / player_id | references | NOT NULL |
| name | string | NOT NULL, default ""（1弾1種類なら ""） |
| rarity | integer | NOT NULL、1〜5 |

- UNIQUE(topic_id, player_id, name) … 二重登録を防ぐ
- name を NULL でなく "" にしているのは、SQLite で NULL 同士が「別物」扱いになり
  重複を防げないため

### posts（募集）
| カラム | 型 | 制約 |
|---|---|---|
| nickname | string | NOT NULL |
| note | text | |
| status | integer | NOT NULL, default 0（0=募集中 / 1=成立済み） |
| completed_at | datetime | |

### wishes / offers（募集とカードをつなぐ）
| カラム | 型 | 制約 |
|---|---|---|
| post_id / card_id | references | NOT NULL、(post_id, card_id) で UNIQUE |

---

## 3. モデルの責務

- **Topic**: `belongs_to :board` / `has_many :cards`。`image_path`（`sets/<slug>.jpg`）
- **Team**: `has_many :players`（背番号順）/ `has_many :cards, through: :players`。
  `image_path`（`teams/<slug>.png`）
- **Player**: `belongs_to :team` / `has_many :cards`。背番号はチーム内で一意
- **Card**: `belongs_to :topic, :player`。`label` / `stars` / `picker_label` / `search_text`、
  `delegate :team, to: :player`
- **Post**: `has_many :wanted_cards, through: :wishes` / `has_many :offered_cards, through: :offers`。
  `enum :status`、`complete!`、欲しいカード1枚以上を検証
  - `scope :wanting_topic(topic)` … その弾のカードを欲しがる募集
  - `scope :wanting_team(team)` … そのチームのカードを欲しがる募集

---

## 4. 画面

```
トップ（弾一覧）  ⇄  チーム一覧        ← 切り替えボタン
   ↓ 弾/チームを選ぶ
掲示板
  ├ 見出し（画像・名前・戻るボタン・操作ボタン）… 画面上部に固定
  ├ [収録カード一覧]（モーダル）
  ├ [＋ 新しく募集する]（モーダル）
  ├ 募集中 / 成立済み タブ
  └ 募集一覧
```

### 投稿フォーム（モーダル）

| 項目 | 入力方法 | 必須 |
|---|---|---|
| ニックネーム | テキスト | ○ |
| 欲しいカード | 選手名で検索して複数選択 | ○（1枚以上） |
| 出せるカード | 選手名で検索して複数選択 | |
| 備考 | テキスト | |

- 候補は Stimulus（`card_picker`）で絞り込み、選んだカードはタグとして表示
- 失敗時はモーダルを開いたまま、フォーム内にエラーを出す
- ボタンはモーダル下部に固定

### 表示ルール

| 状態 | 一覧表示 | アカウントID |
|---|---|---|
| 募集中 | 表示 | ログイン済みユーザーにだけ表示（ログイン導入後） |
| 成立済み | 既定は非表示。タブで閲覧可 | **誰にも表示しない** |

- 募集内のカードは**レア度ごとに行を分け**、その中はクラブ順→背番号順
- 各カードにチーム名と弾名を添える
- 収録カード一覧は、弾の掲示板ではクラブ順、チームの掲示板では弾の新しい順

---

## 5. 技術構成

| | |
|---|---|
| Rails | 8.1.3 |
| Ruby | 3.4.10 |
| DB | SQLite 3（開発）。公開時に永続化 or PostgreSQL 移行を判断 |
| フロント | Hotwire（Stimulus）。モーダルは HTML標準の `<dialog>` |
| 実行環境 | Docker / Docker Compose |
| ポート | ホスト 3001 → コンテナ 3000 |

### Stimulus コントローラ

- `card_picker` … カードを名前で検索して複数選ぶ（欲しい／出せる両方で使い回す）
- `modal` … モーダルの開閉
- `toast` … 右上の通知を数秒で消す

---

## 6. マスタデータの管理

`db/seeds/card_sets.yml` が唯一の情報源。`bin/rails db:seed` で反映（冪等）。

| 区画 | 内容 |
|---|---|
| `sets` | 弾。**リリース順（古い順）**で書く。画面では新しい順に並ぶ |
| `teams` | クラブ。書いた順が画面の順になる |
| `players` | 選手（名前・チーム・背番号・ポジション） |
| `lineups` | 弾ごとの収録カード（選手名＋レア度） |

seed は投入前に検証し、次を見つけたら中断して理由を表示する。

- 選手名の表記ゆれ（`players` にいない名前を `lineups` で使っている）
- 同名選手、チーム内の背番号重複
- レア度の範囲外、slug の誤り・重複

### 画像

`app/assets/images/sets/<slug>.jpg` と `teams/<slug>.png` に置くと自動で表示される。
無ければ名前のタイルになる。**公式素材のため git 管理外**。
