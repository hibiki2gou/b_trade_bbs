# Player = 選手。1人の選手が複数の弾に複数のカードを持つ。
# 所属クラブをここに1回だけ持たせることで、情報の重複を避ける。
class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      # 選手名。ここに書いた表記が「正」になる
      t.string :name, null: false
      # 所属クラブ。チーム別の絞り込みに使う。移籍したらここだけ直す
      t.string :team, null: false

      t.timestamps
    end
    # 選手名は重複禁止。「河村勇輝」が2人できると、カードがどちらに
    # 紐づくか分からなくなるため
    add_index :players, :name, unique: true
  end
end
