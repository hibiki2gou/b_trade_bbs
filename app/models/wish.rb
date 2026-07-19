# Wish = 「この募集で、このカードが欲しい」という1件。
# 募集(Post)と欲しいカード(Card)をつなぐ中間モデル。Offer の欲しい版。
class Wish < ApplicationRecord
  belongs_to :post
  belongs_to :card

  # 同じ募集で同じカードを二重に登録しない
  validates :card_id, uniqueness: { scope: :post_id }
end
