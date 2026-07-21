# Team = クラブチーム。弾(Topic)と対になる存在で、こちらを入口にしても
# 募集を辿れるようにする。
class Team < ApplicationRecord
  # このチームに所属する選手。背番号順に並べる（背番号なしは最後）。
  # チームを消したら選手も消える
  has_many :players, -> { order(Arel.sql("jersey_number IS NULL, jersey_number")) },
           dependent: :destroy
  # このチームのカード。
  # 選手からたどるのではなく、カードが直接チームを持つ。
  # これにより、選手が写っていないクラブカードや、
  # 別チームの選手を扱う B.LEAGUE のカードも扱える。
  has_many :cards, dependent: :restrict_with_error

  validates :name, presence: true
  validates :slug, presence: true,
                   uniqueness: true,
                   format: { with: /\A[a-z0-9\-]+\z/,
                             message: "は英小文字・数字・ハイフンだけで入力してください" }

  scope :ordered, -> { order(:position, :id) }

  # チームのロゴ画像のパス。app/assets/images/teams/<slug>.png を指す。
  # 画像が無い間は、ビューで存在チェックしてから使う。
  def image_path
    "teams/#{slug}.png"
  end
end
