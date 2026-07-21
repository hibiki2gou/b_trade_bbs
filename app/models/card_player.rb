# CardPlayer = カードに写っている選手1人ぶん。
# 1枚のカードに複数の選手が写ることがあるため、カードと選手をつなぐ。
class CardPlayer < ApplicationRecord
  belongs_to :card
  belongs_to :player

  # 同じカードに同じ選手を二重に登録しない
  validates :player_id, uniqueness: { scope: :card_id }
end
