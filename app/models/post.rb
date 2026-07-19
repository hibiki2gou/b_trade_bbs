# Post = 募集（トレードの書き込み）。
class Post < ApplicationRecord
  # 欲しいカード（複数）。Wish 中間テーブルを介して Card とつながる。
  # post.wanted_cards で、欲しいカードの一覧が Card として取れる。
  has_many :wishes, dependent: :destroy
  has_many :wanted_cards, through: :wishes, source: :card

  # 出せるカード（複数）。Offer 中間テーブルを介して Card とつながる。
  has_many :offers, dependent: :destroy
  has_many :offered_cards, through: :offers, source: :card

  # 募集の状態。open = 募集中、completed = 成立済み。
  # DB には 0 / 1 の数字で入るが、コードでは post.open? のように名前で扱える
  enum :status, { open: 0, completed: 1 }

  validates :nickname, presence: true, length: { maximum: 30 }
  validates :note, length: { maximum: 1000 }
  # 欲しいカードは最低1枚は選ぶこと
  validate :must_have_wanted_card

  # よく使う絞り込み。使い方: Post.open_posts / Post.completed_posts
  scope :open_posts, -> { where(status: :open) }
  scope :completed_posts, -> { where(status: :completed) }
  scope :recent, -> { order(created_at: :desc) }

  # 指定の弾のカードを1枚でも欲しがっている募集。
  # その弾の掲示板に表示する募集を選ぶのに使う。
  # 使い方: Post.wanting_topic(topic)
  scope :wanting_topic, ->(topic) {
    joins(:wanted_cards).where(cards: { topic_id: topic.id }).distinct
  }

  # 指定のチームのカードを1枚でも欲しがっている募集。
  # 欲しいカード → 選手 → チーム、とたどって絞り込む。
  # 使い方: Post.wanting_team(team)
  scope :wanting_team, ->(team) {
    joins(wanted_cards: :player).where(players: { team_id: team.id }).distinct
  }

  # 成立ボタンを押したときの処理。状態を「成立済み」にして日時を記録する
  def complete!
    update!(status: :completed, completed_at: Time.current)
  end

  private

  def must_have_wanted_card
    errors.add(:base, "欲しいカードを1枚以上選んでください") if wanted_cards.empty?
  end
end
