# Wish = 「この募集で、このカードが欲しい」を表す中間テーブル。
# 募集(Post)と、欲しいカード(Card)を多対多でつなぐ。
# 出せるカード（Offer）と対になる、欲しいカード版。
class CreateWishes < ActiveRecord::Migration[8.1]
  def change
    create_table :wishes do |t|
      # どの募集の希望か
      t.references :post, null: false, foreign_key: true
      # 欲しいカード
      t.references :card, null: false, foreign_key: true

      t.timestamps
    end
    # 同じ募集で同じカードを二重に欲しがれないようにする
    add_index :wishes, [ :post_id, :card_id ], unique: true
  end
end
