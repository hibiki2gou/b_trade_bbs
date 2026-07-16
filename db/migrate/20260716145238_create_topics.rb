# Topic = スレッド。このアプリでは「弾（カードセット）」が Topic にあたる。
# 例: 記録達成カード / アワードカード / クリスマスカード
# どの Board（カテゴリ）に属するかを board_id で持つ。
class CreateTopics < ActiveRecord::Migration[8.1]
  def change
    create_table :topics do |t|
      # どのカテゴリに属する弾か。foreign_key: true で boards テーブルと紐づく
      t.references :board, null: false, foreign_key: true
      # 弾の名前。画面に表示される
      t.string :name, null: false
      # 弾の名札（英数字）。YAML の cards から参照される。例: record
      # 将来 app/assets/images/sets/record.jpg のように画像名にも使う
      t.string :slug, null: false
      # 弾の説明文。無くてもよい
      t.text :description
      # 一覧に並べる順番
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    # slug は同じカテゴリの中で重複しなければよい（board をまたげば同名OK）
    add_index :topics, [:board_id, :slug], unique: true
  end
end
