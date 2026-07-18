# Offer = 「この募集で、このカードを出せる」という1件。
# 募集(Post)と出せるカード(Card)をつなぐ中間モデル。
class Offer < ApplicationRecord
  belongs_to :post
  belongs_to :card

  # 同じ募集で同じカードを二重に登録しない
  validates :card_id, uniqueness: { scope: :post_id }
end
