# Topic = 弾（カードセット）。スレッドにあたる。
class Topic < ApplicationRecord
  # どのカテゴリに属するか
  belongs_to :board

  # この弾に収録されているカード。弾を消したらカードも消える
  has_many :cards, dependent: :destroy

  # ※ かつて has_many :posts があったが、欲しいカードを複数化したときに
  #    posts.topic_id を廃止したため削除した。
  #    この弾の募集は「欲しいカードがこの弾に属する募集」なので、
  #    Post.wanting_topic(topic) で取得する。

  validates :name, presence: true
  validates :slug, presence: true,
                   format: { with: /\A[a-z0-9\-]+\z/,
                             message: "は英小文字・数字・ハイフンだけで入力してください" },
                   # slug は同じカテゴリ内で重複しなければよい
                   uniqueness: { scope: :board_id }

  scope :ordered, -> { order(:position, :id) }

  # 弾の画像のパス。app/assets/images/sets/<slug>.jpg を指す。
  # 画像はまだ用意していないので、ビューで存在チェックしてから使う。
  def image_path
    "sets/#{slug}.jpg"
  end
end
