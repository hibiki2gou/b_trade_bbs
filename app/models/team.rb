# Team = クラブチーム。弾(Topic)と対になる存在で、こちらを入口にしても
# 募集を辿れるようにする。
class Team < ApplicationRecord
  # このチームに所属する選手。チームを消したら選手も消える
  has_many :players, -> { order(:name) }, dependent: :destroy
  # 選手を通じて、このチームのカードを辿れる。使い方: team.cards
  has_many :cards, through: :players

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
