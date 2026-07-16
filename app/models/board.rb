# Board = カテゴリ（掲示板の大きな区分け）。
class Board < ApplicationRecord
  # 1つのカテゴリは複数の弾(Topic)を持つ。position 順に並べる。
  # dependent: :destroy = カテゴリを消したら中の弾も一緒に消える
  has_many :topics, -> { order(:position) }, dependent: :destroy

  # 入力ルール（バリデーション）
  validates :name, presence: true
  validates :slug, presence: true,
                   uniqueness: true,
                   # slug は URL に使うので、英小文字・数字・ハイフンだけ許可
                   format: { with: /\A[a-z0-9\-]+\z/,
                             message: "は英小文字・数字・ハイフンだけで入力してください" }

  # position の昇順で並べる。使い方: Board.ordered
  scope :ordered, -> { order(:position, :id) }
end
