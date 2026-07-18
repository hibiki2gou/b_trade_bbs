# Offer = 「この募集で、このカードを出せる」を表す中間テーブル。
# 募集(Post)と、出せるカード(Card)を多対多でつなぐ。
# 1つの募集は複数のカードを出せる（富樫SR・渡邊SR…）ので、その1枚ずつが1行になる。
class CreateOffers < ActiveRecord::Migration[8.1]
  def change
    create_table :offers do |t|
      # どの募集の提供か
      t.references :post, null: false, foreign_key: true
      # 出せるカード
      t.references :card, null: false, foreign_key: true

      t.timestamps
    end
    # 同じ募集で同じカードを二重に出せないようにする
    add_index :offers, [ :post_id, :card_id ], unique: true
  end
end
