# Card = カード。選手(player) × 弾(topic) の交差点。
class Card < ApplicationRecord
  belongs_to :topic   # どの弾に収録されたか
  belongs_to :player  # どの選手か

  # このカードを「欲しいカード」に指定している募集。
  # restrict_with_error = 募集から参照されているカードは消せない
  # （消すと募集が宙に浮くため）。外部キー名は wanted_card_id
  has_many :posts, foreign_key: :wanted_card_id, dependent: :restrict_with_error,
                   inverse_of: :wanted_card

  # このカードを「出せるカード」に含んでいる募集（Offer 経由）。
  # 提供されているカードも、募集がある限り消せない
  has_many :offers, dependent: :restrict_with_error
  has_many :offering_posts, through: :offers, source: :post

  # レア度は 1〜5 の数字のみ許可
  validates :rarity, presence: true,
                     inclusion: { in: 1..5, message: "は1〜5で入力してください" }
  # 同じ選手・同じ弾の中では、カード名が重複しないこと。
  # name が空文字("")のカードは「その弾に1種類だけ」を意味する
  validates :name, uniqueness: { scope: [ :topic_id, :player_id ] }

  # 選手の所属クラブは Player が持っているので、card.team で引けるようにする
  delegate :team, to: :player

  # 画面表示用: 「河村勇輝（得点記録）」または「河村勇輝」
  def label
    name.present? ? "#{player.name}（#{name}）" : player.name
  end

  # レア度を★で表す。例: rarity 4 → "★★★★☆"
  def stars
    "★" * rarity + "☆" * (5 - rarity)
  end

  # 選択肢（プルダウン）用の見やすいラベル。
  # 例: 「河村勇輝（得点記録） ★★★★★ / 記録達成カード」
  # 弾をまたぐチームの掲示板でも、どの弾のカードか分かるようにする。
  def picker_label
    "#{label} #{stars} / #{topic.name}"
  end

  def search_text
    [ player.name, name, player.team.name, topic.name ].join(" ").downcase
  end
end
