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

  # 選手名は全体で一意。同名の別人が現れたら、区別できる表記に変える必要がある。
  validates :name, presence: true, uniqueness: true
  # 背番号は 0〜99。未設定でもよい
  validates :jersey_number, numericality: { only_integer: true, in: 0..99 },
                            allow_nil: true
  # 同じチーム内で背番号は重複しない
  validates :jersey_number, uniqueness: { scope: :team_id }, allow_nil: true

  # 名前順（選手を横断して探すとき用）
  scope :ordered, -> { order(:name) }
  # 背番号順（チーム内の一覧表示に使う。背番号なしは最後）
  scope :by_number, -> { order(Arel.sql("jersey_number IS NULL, jersey_number")) }

  # 画面表示用: 「#2 富樫勇樹（PG）」のように背番号とポジションを添える
  def label_with_number
    parts = []
    parts << "##{jersey_number}" if jersey_number
    parts << name
    parts << "（#{position}）" if position.present?
    parts.join(" ")
  end
end
