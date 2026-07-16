# Post = 募集（トレードの書き込み）。
class Post < ApplicationRecord
  belongs_to :topic  # どの弾スレッドへの書き込みか

  # 欲しいカード。wanted_card_id は cards テーブルを指すが、
  # 名前が "Card" と一致しないので class_name で教える
  belongs_to :wanted_card, class_name: "Card", inverse_of: :posts

  # 募集の状態。open = 募集中、completed = 成立済み。
  # DB には 0 / 1 の数字で入るが、コードでは post.open? のように名前で扱える
  enum :status, { open: 0, completed: 1 }

  validates :nickname, presence: true, length: { maximum: 30 }
  validates :offered_cards, length: { maximum: 500 }
  validates :note, length: { maximum: 1000 }

  # よく使う絞り込み。使い方: Post.open_posts / Post.completed_posts
  scope :open_posts, -> { where(status: :open) }
  scope :completed_posts, -> { where(status: :completed) }
  scope :recent, -> { order(created_at: :desc) }

  # 成立ボタンを押したときの処理。状態を「成立済み」にして日時を記録する
  def complete!
    update!(status: :completed, completed_at: Time.current)
  end
end
