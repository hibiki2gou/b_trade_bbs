# Card = カード。「どの選手の、どの弾の、何というカードか」を表す。
# 選手(player) × 弾(topic) の交差点。同じ選手でも弾が違えば別カード、
# 同じ弾でもカード名(得点記録/アシスト記録)が違えば別カード。
class CreateCards < ActiveRecord::Migration[8.1]
  def change
    create_table :cards do |t|
      # どの弾に収録されたカードか
      t.references :topic, null: false, foreign_key: true
      # どの選手のカードか
      t.references :player, null: false, foreign_key: true
      # カード名（得点記録・アシスト記録 など）。
      # 1つの弾に1種類しかない選手のカードは名前が無いので、その場合は空文字 ""。
      # null ではなく "" にするのは、下の重複禁止インデックスを正しく効かせるため
      # （SQLite では null 同士は「別物」扱いになり、重複を防げないため）
      t.string :name, null: false, default: ""
      # レア度。1〜5 の数字。画面では ★ に変換する
      t.integer :rarity, null: false

      t.timestamps
    end
    # 同じ選手・同じ弾・同じカード名 の組み合わせは1枚だけ（二重登録の防止）
    add_index :cards, [:topic_id, :player_id, :name], unique: true
  end
end
