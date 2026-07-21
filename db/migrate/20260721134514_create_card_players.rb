# CardPlayer = カードに写っている選手。
# 1枚のカードに複数の選手が写ることがある（1on1 など）ため、
# カードと選手を多対多でつなぐ。選手が写らないカード（クラブカード）もある。
class CreateCardPlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :card_players do |t|
      t.references :card, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true

      t.timestamps
    end
    # 同じカードに同じ選手を二重に登録しない
    add_index :card_players, [ :card_id, :player_id ], unique: true
  end
end
