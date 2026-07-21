# Card = カード。弾(topic)に収録された1枚。
#
# カードには次の種類がある。どれも「所属チーム(team)」を1つ持ち、
# 写っている選手は0人以上。
#   - 選手カード       … 選手1人。team はその選手の所属クラブ
#   - 複数選手カード   … 選手2人以上（1on1 など）。同じクラブならそのクラブ、
#                        別クラブにまたがるなら B.LEAGUE
#   - クラブカード     … 選手0人。team はそのクラブ
class Card < ApplicationRecord
  belongs_to :topic  # どの弾に収録されたか
  belongs_to :team   # このカードがどのチームの掲示板に出るか

  # 写っている選手（0人以上）
  has_many :card_players, dependent: :destroy
  has_many :players, through: :card_players

  # このカードを「欲しいカード」に含んでいる募集（Wish 経由）。
  # restrict_with_error = 募集から参照されているカードは消せない
  has_many :wishes, dependent: :restrict_with_error
  has_many :wishing_posts, through: :wishes, source: :post

  # このカードを「出せるカード」に含んでいる募集（Offer 経由）。
  has_many :offers, dependent: :restrict_with_error
  has_many :offering_posts, through: :offers, source: :post

  validates :rarity, presence: true,
                     inclusion: { in: 1..5, message: "は1〜5で入力してください" }
  # 同じ弾の中で、同じ内容のカードが二重に登録されないようにする
  validates :key, presence: true, uniqueness: { scope: :topic_id }
  validate :name_required_unless_single_player

  # key は内容から自動で組み立てる（保存のたびに作り直す）
  before_validation :build_key

  # 画面表示用の名前。
  #   選手1人  … 「河村勇輝」または「河村勇輝（得点記録）」
  #   それ以外 … カード名をそのまま（「青木保憲 vs 渡辺翔太」「滋賀レイクス」など）
  def label
    if single_player?
      name.present? ? "#{players.first.name}（#{name}）" : players.first.name
    else
      name
    end
  end

  # レア度を★で表す。例: rarity 4 → "★★★★☆"
  def stars
    "★" * rarity + "☆" * (5 - rarity)
  end

  # 選択肢（プルダウン）用の見やすいラベル。
  # 例: 「河村勇輝 ★★★★★ / 記録達成」
  def picker_label
    "#{label} #{stars} / #{topic.name}"
  end

  # 一覧を並べるときの副キー。写っている選手の背番号を使う。
  # 選手がいないカード（クラブカード）は末尾に寄せる。
  def sort_number
    players.filter_map(&:jersey_number).min || 999
  end

  # 検索用のテキスト。写っている全選手・カード名・チーム名・弾名をつなげる
  def search_text
    ([ name ] + players.map(&:name) + [ team.name, topic.name ]).join(" ").downcase
  end

  private

  def single_player?
    players.size == 1
  end

  # 選手が1人でないカード（複数選手・クラブカード）は、
  # 表示に使う名前が無いと何のカードか分からなくなる
  def name_required_unless_single_player
    return if single_player? || name.present?

    errors.add(:name, "は、選手が1人でないカードには必要です")
  end

  # カードの内容から識別子を組み立てる。
  # 選手がいれば選手の組み合わせ、いなければチームで区別する。
  def build_key
    ids = players.map(&:id).compact.sort
    self.key = if ids.any?
                 "players:#{ids.join(',')}:#{name}"
    else
                 "team:#{team_id}:#{name}"
    end
  end
end
