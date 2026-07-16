# Player = 選手。1人が複数の弾に複数のカードを持つ。
class Player < ApplicationRecord
  # この選手のカード。選手を消したらカードも消える
  has_many :cards, dependent: :destroy
  # カードを通じて、この選手が登場する弾を辿れる。
  # 使い方: player.topics （重複を除くため distinct）
  has_many :topics, -> { distinct }, through: :cards

  validates :name, presence: true, uniqueness: true
  validates :team, presence: true

  scope :ordered, -> { order(:name) }
end
