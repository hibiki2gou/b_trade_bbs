# Board = 掲示板の大きな区分け（カテゴリ）。
# 例: トレード募集 / トレード成立報告 / 雑談・質問
class CreateBoards < ActiveRecord::Migration[8.1]
  def change
    create_table :boards do |t|
      # 画面に表示するカテゴリ名。null: false = 空では保存できない
      t.string :name, null: false
      # URL に使う英数字の名札。例: /boards/trade
      t.string :slug, null: false
      # カテゴリの説明文。無くてもよいので null 指定なし
      t.text :description
      # 一覧に並べる順番。小さいほど上。既定は 0
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    # slug は URL の identity なので重複禁止
    add_index :boards, :slug, unique: true
  end
end
