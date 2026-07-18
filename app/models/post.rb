# Post = 募集（トレードの書き込み）。
class Post < ApplicationRecord
  belongs_to :topic  # どの弾スレッドへの書き込みか

  # 欲しいカード。wanted_card_id は cards テーブルを指すが、
  # 名前が "Card" と一致しないので class_name で教える
  belongs_to :wanted_card, class_name: "Card", inverse_of: :posts

  # 出せるカード（複数）。Offer 中間テーブルを介して Card とつながる。
  # post.offered_cards で、出せるカードの一覧が Card として取れる。
  has_many :offers, dependent: :destroy
  has_many :offered_cards, through: :offers, source: :card

  # 募集の状態。open = 募集中、completed = 成立済み。
  # DB には 0 / 1 の数字で入るが、コードでは post.open? のように名前で扱える
  enum :status, { open: 0, completed: 1 }

  # 募集の弾(topic)は、必ず「欲しいカード」の弾になる。
  # フォームでは弾を送らず、欲しいカードから自動で決める。
  before_validation :set_topic_from_wanted_card

  validates :nickname, presence: true, length: { maximum: 30 }
  validates :note, length: { maximum: 1000 }

  # よく使う絞り込み。使い方: Post.open_posts / Post.completed_posts
  scope :open_posts, -> { where(status: :open) }
  scope :completed_posts, -> { where(status: :completed) }
  scope :recent, -> { order(created_at: :desc) }

  # 欲しいカードが指定のチームに属する募集だけを取り出す。
  # 欲しいカード → 選手 → チーム、とたどって絞り込む。
  # 使い方: Post.wanting_team(team)
  scope :wanting_team, ->(team) {
    joins(wanted_card: :player).where(players: { team_id: team.id })
  }

  # 成立ボタンを押したときの処理。状態を「成立済み」にして日時を記録する
  def complete!
    update!(status: :completed, completed_at: Time.current)
  end

  private

  # topic が未設定なら、欲しいカードの弾を使う
  def set_topic_from_wanted_card
    self.topic ||= wanted_card&.topic
  end
end
