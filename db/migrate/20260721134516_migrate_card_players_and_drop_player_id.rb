# 既存カードの「選手1人」を中間テーブル(card_players)へ移し、
# cards.player_id を廃止する。
#
# あわせて、カードの重複を防ぐ索引を張り直す。
# 旧: (topic_id, player_id, name) … 選手が1人であることが前提だった
# 新: (topic_id, key)             … key はカードの内容から組み立てる識別子
#     （選手の組み合わせ／チーム／カード名から決まる。Card モデルが自動で入れる）
class MigrateCardPlayersAndDropPlayerId < ActiveRecord::Migration[8.1]
  def up
    # 1. 既存の1人1枚を中間テーブルへ複写する
    execute <<~SQL
      INSERT INTO card_players (card_id, player_id, created_at, updated_at)
      SELECT id, player_id, datetime('now'), datetime('now') FROM cards
    SQL

    # 2. 識別子の列を用意し、既存カードぶんを埋める
    add_column :cards, :key, :string
    execute <<~SQL
      UPDATE cards
      SET key = 'players:' || player_id || ':' || COALESCE(name, '')
    SQL
    change_column_null :cards, :key, false

    # 3. 旧い索引と列を外し、新しい索引を張る
    remove_index :cards, column: [ :topic_id, :player_id, :name ]
    remove_reference :cards, :player, foreign_key: true
    add_index :cards, [ :topic_id, :key ], unique: true
  end

  def down
    remove_index :cards, column: [ :topic_id, :key ]
    add_reference :cards, :player, foreign_key: true
    execute <<~SQL
      UPDATE cards
      SET player_id = (
        SELECT player_id FROM card_players WHERE card_players.card_id = cards.id LIMIT 1
      )
    SQL
    remove_column :cards, :key
    add_index :cards, [ :topic_id, :player_id, :name ], unique: true
  end
end
