# Player = 選手。1人が複数の弾に複数のカードを持つ。
class Player < ApplicationRecord
  # 所属クラブ。文字列ではなく Team モデルへの参照になった。
  # belongs_to は既定で「存在必須」を検査するので、team の presence 検証は不要。
  belongs_to :team

  # この選手のカード。選手を消したらカードも消える
  has_many :cards, dependent: :destroy
  # カードを通じて、この選手が登場する弾を辿れる。
  # 使い方: player.topics （重複を除くため distinct）
  has_many :topics, -> { distinct }, through: :cards

  validates :name, presence: true, uniqueness: true

  scope :ordered, -> { order(:name) }
end
