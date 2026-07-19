# 選手に背番号とポジションを持たせる。
#   jersey_number … 背番号。チーム内の一覧をこの順で並べるのに使う
#   position      … ポジション（例: SG/SF）。将来の検索・絞り込みに使う
# どちらも不明な選手がいてもよいので null 可。
class AddJerseyNumberAndPositionToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :jersey_number, :integer
    add_column :players, :position, :string

    # 同じチーム内で背番号は重複しない（データの打ち間違いを検出できる）。
    # 背番号が未設定(null)の選手は対象外。
    add_index :players, [ :team_id, :jersey_number ], unique: true
  end
end
